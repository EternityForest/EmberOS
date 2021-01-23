
set -e
set -x

! rm workspace-micro_variant/emberos_micro_postprocessed.img

echo "postprocessing `ls -t workspace-micro_variant/*.img | head -1`"

ORIGINAL_LOOP=$(losetup -P -r --find --show `ls -t workspace-micro_variant/*.img | head -1`)

dd if=/dev/zero bs=1M count=6248 >> workspace-micro_variant/emberos_micro_postprocessed.img

POSTPROCESS_LOOP=`losetup -P --find --show workspace-micro_variant/emberos_micro_postprocessed.img`


mkdir -p workspace-micro_variant/original_boot
mkdir -p workspace-micro_variant/original_root

mount ${ORIGINAL_LOOP}p1 workspace-micro_variant/original_boot/
mount ${ORIGINAL_LOOP}p2 workspace-micro_variant/original_root/


#Remove the root, resize boot to end at 320MB so it's a known size
#We should be able to get a
parted --script ${POSTPROCESS_LOOP} \
    mklabel msdos \
    mkpart primary fat32 4MiB 192MiB \
    mkpart primary btrfs 192MiB 5120MiB \
    mkpart primary NTFS 5120MiB 6200MiB \
    set 1 boot on
    set 2 boot on
    set 1 lba on



#Remount to get the partition table
losetup -d ${POSTPROCESS_LOOP}
POSTPROCESS_LOOP=`losetup -P --find --show workspace-micro_variant/emberos_micro_postprocessed.img`


sudo mkfs.vfat -F 32 -n 'boot' ${POSTPROCESS_LOOP}p1
#mkfs.f2fs -l "root" -O encrypt,compression,extra_attr -t 0 ${POSTPROCESS_LOOP}p2
#mkfs.ext4 -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.btrfs -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.ntfs -C -L "sketch" ${POSTPROCESS_LOOP}p3

mkdir -p workspace-micro_variant/postprocess_root/
mkdir -p workspace-micro_variant/postprocess_boot/
mkdir -p workspace-micro_variant/postprocess_sketch/

mount ${POSTPROCESS_LOOP}p1 workspace-micro_variant/postprocess_boot/

#Copy the boot partition unchanged
rsync -az workspace-micro_variant/original_boot/ workspace-micro_variant/postprocess_boot/

#Then edit the cmd line. Pretty sure rootfstype is ignored by tmpfs though but whatever.
sed -i 's/rootfstype=ext4/rootfstype=btrfs/g' workspace-micro_variant/postprocess_boot/cmdline.txt
sed -i 's/fsck.repair=yes/fsck.repair=no/g' workspace-micro_variant/postprocess_boot/cmdline.txt


#Maximum zstd compression ratio
mount -o compress-force=zstd:15 ${POSTPROCESS_LOOP}p2 workspace-micro_variant/postprocess_root/
mount -t ntfs-3g -o compression ${POSTPROCESS_LOOP}p3 workspace-micro_variant/postprocess_sketch/

#Set compression attrs, on everything.  This will cause all new dubdirs to be recursively marked for compression.
#Must happen before we put anything in
setfattr -h -v 0x00000800 -n system.ntfs_attrib_be workspace-micro_variant/postprocess_sketch/

mkdir -p workspace-micro_variant/postprocess_sketch/public.media
mkdir -p workspace-micro_variant/postprocess_sketch/public.files
mkdir -p workspace-micro_variant/postprocess_sketch/public.www
mkdir -p workspace-micro_variant/postprocess_sketch/home
setfattr -h -v 0x00000800 -n system.ntfs_attrib_be workspace-micro_variant/postprocess_sketch/public.media
setfattr -h -v 0x00000800 -n system.ntfs_attrib_be workspace-micro_variant/postprocess_sketch/public.files
setfattr -h -v 0x00000800 -n system.ntfs_attrib_be workspace-micro_variant/postprocess_sketch/public.www
setfattr -h -v 0x00000800 -n system.ntfs_attrib_be workspace-micro_variant/postprocess_sketch/home

#Copy all files from root, compressing as we go if we were using a compression friendly FS
rsync -az --exclude='/tmp/*' --exclude='/var/tmp/*' workspace-micro_variant/original_root/ workspace-micro_variant/postprocess_root/


#Change the fstab to look for a btrfs, and to enable compression on everything.
sed -i '/mmcblk0p2/c\\/dev\/mmcblk0p2  \/               btrfs    defaults,noatime,ro,compress-force=zstd  0       1' workspace-micro_variant/postprocess_root/etc/fstab

#Use BTRFS deduplication to save a bit of space
jdupes --recurse --dedupe --size workspace-micro_variant/postprocess_root/
  



#Copy the sketch stuff from the master image
rsync -az workspace-micro_variant/original_root/sketch/ workspace-micro_variant/postprocess_sketch/

#Delete and /sketch in root since that is just a mountpoint now
! rm -rf workspace-micro_variant/postprocess_root/sketch
mkdir -p workspace-micro_variant/postprocess_root/sketch



#Now transfer the actual files over, into the dirs marked for compression
rsync -az --exclude="home/pi/.local/share/Zeal/Zeal/docsets/**" --exclude="public.files/emberos/clipart/**" --exclude="public.files/emberos/textbooks/**" --exclude="public.files/emberos/fonts/**" --exclude="public.files/emberos/articles/**" --exclude="public.media/emberos/sounds/**" --exclude="public.media/emberos/Music/**" --exclude="public.files/emberos/Stock Photos/**" --exclude="public.files/emberos/books/**" --exclude="public.files/emberos/Textures/**" --exclude="share/wikis/**" --exclude="public.files/emberos/Textures/**" --exclude="public.files/emberos/icons/**" sketch_included_data/sketch/ workspace-micro_variant/postprocess_sketch/

rsync -az --exclude='arduino-1.8.13' sketch_included_data/root.opt/ workspace-micro_variant/postprocess_root/opt/

#No, I do not have the slightest idea why all attempts to fix this in the actual build fail.
rsync -az sketch_included_data/mime/ workspace/postprocess_root/usr/share/mime/
chmod -R 755 workspace/postprocess_root/usr/share/mime/


#Make it not a submodule
rm workspace-micro_variant/postprocess_sketch/opt/kaithem/.git

cd workspace-micro_variant/postprocess_sketch/
git init
git add -A

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
