set -e
set -x

mkdir -p workspace/postprocess
! rm workspace/postprocess/emberos_postprocessed.img
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"$LD_LIBRARY_PATH:"}/usr/lib/libeatmydata
LD_PRELOAD=${LD_PRELOAD:+"$LD_PRELOAD "}libeatmydata.so
echo "postprocessing `ls -t workspace/*.img | head -1`"

ORIGINAL_LOOP=$(losetup -P -r --find --show `ls -t workspace/*.img | head -1`)

dd if=/dev/zero bs=1M count=7024 >> workspace/postprocess/emberos_postprocessed.img

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
    mkpart primary btrfs 192MiB 6712MiB \
    mkpart primary ext4  6712MiB 7000MiB \
    set 1 boot on
    set 2 boot on
    set 1 lba on



# #Remount to get the partition table
losetup -d ${POSTPROCESS_LOOP}
POSTPROCESS_LOOP=`losetup -P --find --show workspace/postprocess/emberos_postprocessed.img`




sudo mkfs.vfat -F 32 -n 'boot' ${POSTPROCESS_LOOP}p1
mkfs.btrfs --mixed -U 33fc23d5-a31d-45ed-8aec-e85f4fb4a436 -L "root" ${POSTPROCESS_LOOP}p2 
mkfs.ext4 -U c8dd1d93-222c-42e5-9b03-82c24d2433fd -I 256 -L "sketch" ${POSTPROCESS_LOOP}p3


mkdir -p workspace/postprocess_root/
mkdir -p workspace/postprocess_boot/
mkdir -p workspace/postprocess_sketch/

mount ${POSTPROCESS_LOOP}p1 workspace/postprocess_boot/
mount -t btrfs -o compress-force=zstd:15 ${POSTPROCESS_LOOP}p2 workspace/postprocess_root/

#Copy the boot partition unchanged
rsync -az workspace/original_boot/ workspace/postprocess_boot/

#Then edit the cmd line. Pretty sure rootfstype is ignored by initramfs though but whatever.
sed -i 's/rootfstype=ext4/rootfstype=btrfs,ext4,f2fs/g' workspace/postprocess_boot/cmdline.txt
sed -i 's/fsck.repair=yes/fsck.repair=no/g' workspace/postprocess_boot/cmdline.txt



mount -t ext4 ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch/


#Copy all files from root, compressing as we go if we were using a compression friendly FS
eatmydata rsync -az --exclude='sketch/*' --exclude='/tmp/*' --exclude='/var/tmp/*' workspace/original_root/ workspace/postprocess_root/

find workspace/postprocess_root/usr/share/games/ardentryst/Data -name '*.png' -exec pngquant --ext .png --force 256 {} \;
find workspace/postprocess_root/usr/share/games/brainparty -name '*.png' -exec pngquant --ext .png --force 256 {} \;


# Make some space by fixing about 1GiB (Prob more like 300MB compressed) of duplicates.
tmux -c "duperemove -rd workspace/postprocess_root/"


sed -i '/23709a26-1289-4e83-bfe5-2c99d42d276e/c\/dev/mmcblk0p1  /boot           vfat    defaults,noatime,rw         0       0' workspace/postprocess_root/etc/fstab

# sed -i '/33fc23d5-a31d-45ed-8aec-e85f4fb4a436/c\/dev/mmcblk0p2  /               btrfs    defaults,noatime,ro,compress  0       1' workspace/postprocess_root/etc/fstab
# sed -i '/c8dd1d93-222c-42e5-9b03-82c24d2433fd/c\/dev/mmcblk0p3 /sketch auto defaults,noatime,nofail,fmask=027,dmask=027,umask=027 0 1' workspace/postprocess_root/etc/fstab



mkdir -p workspace/postprocess_sketch/default


# Have to install this to build https://github.com/Lakshmipathi/dduper
#Copy the sketch stuff from the master image
eatmydata rsync -az workspace/original_root/sketch/ workspace/postprocess_sketch/

#Delete and /sketch in root since that is just a mountpoint now
! rm -rf workspace/postprocess_root/sketch
mkdir -p workspace/postprocess_root/sketch
chown root workspace/postprocess_root/sketch


# The actual image no longer includes this
! rm -rf workspace/postprocess_root/opt/dotnet/*

mkdir -p /workspace/postprocess_root/usr/share/genact/
mkdir -p /workspace/postprocess_root/usr/share/zimwikis/

mkdir -p /workspace/postprocess_root/usr/share/public.files/
mkdir -p /workspace/postprocess_root/usr/share/public.media/

rsync -az --ignore-existing sketch_included_data/root/usr/bin workspace/postprocess_root/usr/bin
rsync -az --ignore-existing sketch_included_data/root/home/ workspace/postprocess_root/home/
rsync -az --ignore-existing sketch_included_data/root/opt/ workspace/postprocess_root/opt/
rsync -az --ignore-existing sketch_included_data/root/usr/share/zimwikis/ workspace/postprocess_root/usr/share/zimwikis/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/books
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/books/" workspace/postprocess_root/usr/share/public.files/emberos/books/



mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/Artwork/Rembrandt
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/Artwork/Rembrandt/" workspace/postprocess_root/usr/share/public.files/emberos/Artwork/Rembrandt/


mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/Artwork/Rosa Bonheur
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/Artwork/Rosa Bonheur/" workspace/postprocess_root/usr/share/public.files/emberos/Artwork/Rosa Bonheur/


mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/articles
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/articles/" "workspace/postprocess_root/usr/share/public.files/emberos/articles/"

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Nicu SVG Pack/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/CC0 Nicu SVG Pack/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Nicu SVG Pack/


mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/GeraldGCC0/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/GeraldGCC0/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/GeraldGCC0/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0Tattoo/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/CC0Tattoo/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0Tattoo/


mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/Johnny Automatic CC0/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/Johnny Automatic CC0/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/Johnny Automatic CC0/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Silhouette/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/CC0 Silhouette/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Silhouette/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Portraits/
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/clipart/CC0 Portraits/" workspace/postprocess_root/usr/share/public.files/emberos/clipart/CC0 Portraits/


mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/trivia/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.files/emberos/trivia/ workspace/postprocess_root/usr/share/public.files/emberos/trivia/



mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/fonts/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.files/emberos/fonts/ workspace/postprocess_root/usr/share/public.files/emberos/fonts/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/textfiles/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.files/emberos/textfiles/ workspace/postprocess_root/usr/share/public.files/emberos/textfiles/

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/SoundFonts/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.files/emberos/SoundFonts/ workspace/postprocess_root/usr/share/public.files/emberos/SoundFonts/

mkdir -p "workspace/postprocess_root/usr/share/public.files/emberos/Stock Photos/magdeleine.co CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/Stock Photos/magdeleine.co CC0/" "workspace/postprocess_root/usr/share/public.files/emberos/Stock Photos/magdeleine.co CC0"

mkdir -p "workspace/postprocess_root/usr/share/public.files/emberos/Stock Photos/publicdomainpictures"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.files/emberos/Stock Photos/publicdomainpictures/" "workspace/postprocess_root/usr/share/public.files/emberos/Stock Photos/publicdomainpictures"

mkdir -p workspace/postprocess_root/usr/share/public.files/emberos/Licenses/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.files/emberos/Licenses/ workspace/postprocess_root/usr/share/public.files/emberos/Licenses/


mkdir -p workspace/postprocess_root/usr/share/public.media/emberos/sounds/
rsync -az --ignore-existing sketch_included_data/root/usr/share/public.media/emberos/sounds/ workspace/postprocess_root/usr/share/public.media/emberos/sounds/

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Centurion_of_war CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Centurion_of_war CC0" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Centurion_of_war CC0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/RandomMynd CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/RandomMynd CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/RandomMynd CC0/"


# mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Kevin Mcleod CC-BY"
# rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Kevin Mcleod CC-BY/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Kevin Mcleod CC-BY/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/USAF CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/USAF CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/USAF CC0/"




mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/FreePD CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/FreePD CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/FreePD CC0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/1920s Public Domain"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/1920s Public Domain/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/1920s Public Domain/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/nene CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/nene CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/nene CC0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/CodeManu CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/CodeManu CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/CodeManu CC0/"



mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/cynicmusic CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/cynicmusic CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/cynicmusic CC0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/tricksntraps CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/tricksntraps CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/tricksntraps CC0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Matthew Pablo CC-BY-3.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Matthew Pablo CC-BY-3.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Matthew Pablo CC-BY-3.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Jon Sayles"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Jon Sayles/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Jon Sayles/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Guifrog CC-BY-3.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Guifrog CC-BY-3.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Guifrog CC-BY-3.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Musopen Classical"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Musopen Classical/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Musopen Classical/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Anthem of Rain CC-BY-4.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Anthem of Rain CC-BY-4.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Anthem of Rain CC-BY-4.0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Alexandr Zhelanov CC-BY-4.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Alexandr Zhelanov CC-BY-4.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Alexandr Zhelanov CC-BY-4.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tausdei CC-BY-3.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Tausdei CC-BY-3.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tausdei CC-BY-3.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/TAD+hitctl CC-BY-4.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/TAD+hitctl CC-BY-4.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/TAD+hitctl CC-BY-4.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Turku CC-BY-4.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Turku CC-BY-4.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Turku CC-BY-4.0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/John Bartmann CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/John Bartmann CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/John Bartmann CC0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Umplix CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Umplix CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Umplix CC0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Zane Little CC0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Zane Little CC0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Zane Little CC0/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tsorthan Grove CC-BY-4.0"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Tsorthan Grove CC-BY-4.0/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tsorthan Grove CC-BY-4.0/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Petrifications"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Petrifications/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Petrifications/"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Meditations"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Meditations/" "workspace/postprocess_root/usr/share/public.media/emberos/Music/Tim Kulig CC-BY-3.0/Meditations/"


mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2019 - Digital Hell"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2019 - Digital Hell" "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2019 - Digital Hell"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2016 - Forest Spirits"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2016 - Forest Spirits" "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2016 - Forest Spirits"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2017 - Red Flower"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2017 - Red Flower" "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2017 - Red Flower"

mkdir -p "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2022 - Night"
rsync -az --ignore-existing "sketch_included_data/root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2022 - Night" "workspace/postprocess_root/usr/share/public.media/emberos/Music/DEglTx CC-BY-4.0/2022 - Night"


 
#No, I do not have the slightest idea why all attempts to fix this in the actual build fail.
rsync -az --ignore-existing sketch_included_data/mime/ workspace/postprocess_root/usr/share/mime/
chmod -R 755 workspace/postprocess_root/usr/share/mime/
chmod -R 755 workspace/postprocess_root/usr/share/public.files/
chmod -R 755 workspace/postprocess_root/usr/share/public.media/
chown -R root workspace/postprocess_root/usr/share/public.files/
chown -R root workspace/postprocess_root/usr/share/public.media/


cd workspace/postprocess_root/opt/kaithem
git pull --rebase


cd ../../../..

umount ${POSTPROCESS_LOOP}p1 workspace/postprocess_boot
umount ${POSTPROCESS_LOOP}p2 workspace/postprocess_root
umount ${POSTPROCESS_LOOP}p3 workspace/postprocess_sketch

umount ${ORIGINAL_LOOP}p1 workspace/original_boot
umount ${ORIGINAL_LOOP}p2 workspace/original_root

losetup -d ${ORIGINAL_LOOP}
losetup -d ${POSTPROCESS_LOOP}
