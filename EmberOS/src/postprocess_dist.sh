
set -e
set -x

! rm workspace/emberos_postprocessed.img


ORIGINAL_LOOP=$(losetup -P -r --find --show `ls -t workspace/*.img | head -1`)

dd if=/dev/zero bs=1M count=12000 >> workspace/emberos_postprocessed.img

POSTPROCESS_LOOP=`losetup -P --find --show workspace/emberos_postprocessed.img`


mkdir workspace/original_boot
mkdir workspace/original_root

mount ${ORIGINAL_LOOP}p1 workspace/original_boot/
mount ${ORIGINAL_LOOP}p2 workspace/original_root/


#Remove the root, resize boot to end at 320MB so it's a known size
#We should be able to get a
parted --script ${POSTPROCESS_LOOP} \
    mklabel msdos \
    mkpart primary 4MiB 320MiB \
    mkpart primary 320MiB 5120MiB \
    mkpart primary 5120MiB 7100MiB 


# parted --script ${POSTPROCESS_LOOP} \
#     mklabel msdos \
#     mkpart primary 4MiB 320MiB \
#     mkpart primary 320MiB 10000MiB \
#     mkpart primary 10000MiB 11150MiB 


#Remount to get the partition table
losetup -d ${POSTPROCESS_LOOP}
POSTPROCESS_LOOP=`losetup -P --find --show workspace/emberos_postprocessed.img`


sudo mkfs.vfat -F 32 -n 'BOOT' ${POSTPROCESS_LOOP}p1
#mkfs.f2fs -l "root" -O encrypt,compression,extra_attr -t 0 ${POSTPROCESS_LOOP}p2
#mkfs.ext4 -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.btrfs -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.ntfs -L "sketch" ${POSTPROCESS_LOOP}p3

mkdir -p workspace/postprocess_root/
mkdir -p workspace/postprocess_boot/
mkdir -p workspace/postprocess_sketch/

mount ${POSTPROCESS_LOOP}p1 workspace/postprocess_boot/
mount -o compress-force=zlib:9 ${POSTPROCESS_LOOP}p2 workspace/postprocess_root/
mount -o compression ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch/

#Copy the boot partition unchanged
rsync -az workspace/original_boot/ workspace/postprocess_boot/


#Copy over empty directory structure
rsync -a -f"+ */" -f"- *" workspace/original_root/ workspace/postprocess_root/

#Set the compress attribute on all those folders so that writing will compress.
#Currently does nothing until we change to 
chattr -R +c workspace/postprocess_root/

#Copy all files from root, compressing as we go if we were using a compression friendly FS
rsync -az workspace/original_root/ workspace/postprocess_root/

#We have all this on the sketch partition, no need for two copies.
rm -rf workspace/postprocess_root/sketch/*


#Change the fstab to look for a btrfs, and to enable compression on everything.
sed -i '/mmcblk0p2/c\\/dev\/mmcblk0p2  \/               btrfs    defaults,noatime,ro,compress-force=zlib:2  0       1' workspace/postprocess_root/etc/fstab


#Copy the sketch stuff
rsync -az workspace/original_root/sketch/ workspace/postprocess_sketch/

#NTFS supports compression too, we will use it on some of the PDFs
rsync -a --include='*/' --exclude='*' sketch_included_data/sketch/ workspace/postprocess_sketch/

#Only a few mb max saved here, but it would be awesome if someone could get it to work
#chattr -R +c workspace/postprocess_sketch/public.files/emberos/
#Probably more here
#chattr -R +c workspace/postprocess_sketch/home/pi/Programs/arduino-PR-beta1.9-BUILD-119/
#chattr -R +c workspace/postprocess_sketch/home/pi/.local/share/Zeal/

#Now transfer the actual files over
rsync -az sketch_included_data/sketch/ workspace/postprocess_sketch/

cd workspace/postprocess_sketch/
git init
git add **
git commit -m "First Commit!"


cd ..

umount ${POSTPROCESS_LOOP}p0
umount ${POSTPROCESS_LOOP}p1
umount ${POSTPROCESS_LOOP}p2

umount ${ORIGINAL_LOOP}p0
umount ${ORIGINAL_LOOP}p1

losetup -d ${ORIGINAL_LOOP}
losetup -d ${POSTPROCESS_LOOP}
