
set -e
set -x

! rm workspace/emberos_postprocessed.img

echo "postprocessing `ls -t workspace/*.img | head -1`"

ORIGINAL_LOOP=$(losetup -P -r --find --show `ls -t workspace/*.img | head -1`)

dd if=/dev/zero bs=1M count=7104 >> workspace/emberos_postprocessed.img

POSTPROCESS_LOOP=`losetup -P --find --show workspace/emberos_postprocessed.img`


mkdir -p workspace/original_boot
mkdir -p workspace/original_root

mount ${ORIGINAL_LOOP}p1 workspace/original_boot/
mount ${ORIGINAL_LOOP}p2 workspace/original_root/


#Remove the root, resize boot to end at 320MB so it's a known size
#We should be able to get a
parted --script ${POSTPROCESS_LOOP} \
    mklabel msdos \
    mkpart primary fat32 4MiB 320MiB \
    mkpart primary btrfs 320MiB 5604MiB \
    mkpart primary NTFS 5604MiB 7100MiB \
    set 1 boot on
    set 2 boot on
    set 1 lba on



#Remount to get the partition table
losetup -d ${POSTPROCESS_LOOP}
POSTPROCESS_LOOP=`losetup -P --find --show workspace/emberos_postprocessed.img`


sudo mkfs.vfat -F 32 -n 'boot' ${POSTPROCESS_LOOP}p1
#mkfs.f2fs -l "root" -O encrypt,compression,extra_attr -t 0 ${POSTPROCESS_LOOP}p2
#mkfs.ext4 -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.btrfs -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.ntfs -L "sketch" ${POSTPROCESS_LOOP}p3

mkdir -p workspace/postprocess_root/
mkdir -p workspace/postprocess_boot/
mkdir -p workspace/postprocess_sketch/

mount ${POSTPROCESS_LOOP}p1 workspace/postprocess_boot/

#Copy the boot partition unchanged
rsync -az workspace/original_boot/ workspace/postprocess_boot/

#Then edit the cmd line. Pretty sure rootfstype is ignored by tmpfs though but whatever.
sed -i 's/rootfstype=ext4/rootfstype=btrfs/g' workspace/postprocess_boot/cmdline.txt
sed -i 's/fsck.repair=yes/fsck.repair=no/g' workspace/postprocess_boot/cmdline.txt


#Maximum zstd compression ratio
mount -o compress-force=zlib:9 ${POSTPROCESS_LOOP}p2 workspace/postprocess_root/
mount -o compression ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch/



#Copy over empty directory structure first, we used to set chattrs for compression but we don't need to with btrfs
rsync -a -f"+ */" -f"- *" workspace/original_root/ workspace/postprocess_root/


#Copy all files from root, compressing as we go if we were using a compression friendly FS
rsync -az --exclude='sketch/*' --exclude='/tmp/*' --exclude='/var/tmp/*' workspace/original_root/ workspace/postprocess_root/

#Change the fstab to look for a btrfs, and to enable compression on everything.
sed -i '/mmcblk0p2/c\\/dev\/mmcblk0p2  \/               btrfs    defaults,noatime,ro,compress-force=zstd  0       1' workspace/postprocess_root/etc/fstab


#Copy the sketch stuff
rsync -az workspace/original_root/sketch/ workspace/postprocess_sketch/

#NTFS supports compression too, we will use it on some of the PDFs
rsync -a --include='*/' --exclude='*' sketch_included_data/sketch/ workspace/postprocess_sketch/

#Now transfer the actual files over
rsync -az sketch_included_data/sketch/ workspace/postprocess_sketch/
rsync -az sketch_included_data/root.opt/ workspace/postprocess_root/opt/

cd workspace/postprocess_sketch/
git init
git add **

git config user.email "emberos@example.com"
git config user.name "EmberOS" 

git commit -m "First Commit!"


cd ..

umount ${POSTPROCESS_LOOP}p0
umount ${POSTPROCESS_LOOP}p1
umount ${POSTPROCESS_LOOP}p2

umount ${ORIGINAL_LOOP}p0
umount ${ORIGINAL_LOOP}p1

losetup -d ${ORIGINAL_LOOP}
losetup -d ${POSTPROCESS_LOOP}
