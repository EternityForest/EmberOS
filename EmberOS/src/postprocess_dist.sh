set -e
set -x

mkdir -p workspace/postprocess
! rm workspace/postprocess/emberos_postprocessed.img
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata
LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so
echo "postprocessing `ls -t workspace/*.img | head -1`"

ORIGINAL_LOOP=$(losetup -P -r --find --show `ls -t workspace/*.img | head -1`)

dd if=/dev/zero bs=1M count=12292 >> workspace/postprocess/emberos_postprocessed.img

POSTPROCESS_LOOP=`losetup -P --find --show workspace/postprocess/emberos_postprocessed.img`

mkdir -p workspace/original_boot
mkdir -p workspace/original_root

mount ${ORIGINAL_LOOP}p1 workspace/original_boot/
mount ${ORIGINAL_LOOP}p2 workspace/original_root/


# #Remove the root, resize boot to end at 192MB so it's a known size
# #We should be able to get a
parted --script ${POSTPROCESS_LOOP} \
    mklabel msdos \
    mkpart primary fat32 4MiB 192MiB \
    mkpart primary btrfs 192MiB 9000MiB \
    mkpart primary ext4  9000MiB 10264MiB \
    set 1 boot on
    set 2 boot on
    set 1 lba on



# #Remount to get the partition table
losetup -d ${POSTPROCESS_LOOP}
POSTPROCESS_LOOP=`losetup -P --find --show workspace/postprocess/emberos_postprocessed.img`




sudo mkfs.vfat -F 32 -n 'boot' ${POSTPROCESS_LOOP}p1
mkfs.btrfs -U 33fc23d5-a31d-45ed-8aec-e85f4fb4a436 -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.ext4 -U c8dd1d93-222c-42e5-9b03-82c24d2433fd -I 256 -L "sketch" ${POSTPROCESS_LOOP}p3


mkdir -p workspace/postprocess_root/
mkdir -p workspace/postprocess_boot/
mkdir -p workspace/postprocess_sketch/

mount ${POSTPROCESS_LOOP}p1 workspace/postprocess_boot/

#Copy the boot partition unchanged
rsync -az workspace/original_boot/ workspace/postprocess_boot/

#Then edit the cmd line. Pretty sure rootfstype is ignored by initramfs though but whatever.
sed -i 's/rootfstype=ext4/rootfstype=btrfs,ext4,f2fs/g' workspace/postprocess_boot/cmdline.txt
sed -i 's/fsck.repair=yes/fsck.repair=no/g' workspace/postprocess_boot/cmdline.txt



#mount -o compress_algorithm=zstd ${POSTPROCESS_LOOP}p2 workspace/postprocess_root/
mount -t ext4 ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch/
#mount -o compress_algorithm=zstd ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch/
mount -o compress-force=zstd:15 ${POSTPROCESS_LOOP}p2 workspace/postprocess_root/


#Copy all files from root, compressing as we go if we were using a compression friendly FS
rsync -az --exclude='sketch/*' --exclude='/tmp/*' --exclude='/var/tmp/*' workspace/original_root/ workspace/postprocess_root/


# Make some space by fixing about 1GiB (Prob more like 300MB compressed) of duplicates.
eatmydata tmux -c "duperemove -rd workspace/postprocess_root/"

sed -i '/23709a26-1289-4e83-bfe5-2c99d42d276e/c\/dev/mmcblk0p1  /boot           vfat    defaults,noatime,ro          0       0' workspace/postprocess_root/etc/fstab

# sed -i '/33fc23d5-a31d-45ed-8aec-e85f4fb4a436/c\/dev/mmcblk0p2  /               btrfs    defaults,noatime,ro,compress  0       1' workspace/postprocess_root/etc/fstab
# sed -i '/c8dd1d93-222c-42e5-9b03-82c24d2433fd/c\/dev/mmcblk0p3 /sketch auto defaults,noatime,nofail,fmask=027,dmask=027,umask=027 0 1' workspace/postprocess_root/etc/fstab



mkdir -p workspace/postprocess_sketch/default

#Copy the sketch stuff from the master image
rsync -az workspace/original_root/sketch/ workspace/postprocess_sketch/

#Delete and /sketch in root since that is just a mountpoint now
! rm -rf workspace/postprocess_root/sketch
mkdir -p workspace/postprocess_root/sketch
chown root workspace/postprocess_root/sketch


#Now transfer the actual files over, into the dirs marked for compression
rsync -az --ignore-existing sketch_included_data/root/ workspace/postprocess_root/

#No, I do not have the slightest idea why all attempts to fix this in the actual build fail.
rsync -az --ignore-existing sketch_included_data/mime/ workspace/postprocess_root/usr/share/mime/
chmod -R 755 workspace/postprocess_root/usr/share/mime/

# Another dedupe pass because we can.
eatmydata tmux -c "duperemove -rd workspace/postprocess_root/"

cd workspace/postprocess_sketch/

cd ..

umount ${POSTPROCESS_LOOP}p0
umount ${POSTPROCESS_LOOP}p1
umount ${POSTPROCESS_LOOP}p2

umount ${ORIGINAL_LOOP}p0
umount ${ORIGINAL_LOOP}p1

losetup -d ${ORIGINAL_LOOP}
losetup -d ${POSTPROCESS_LOOP}
