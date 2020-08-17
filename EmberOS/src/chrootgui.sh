set -x
set -e

! mkdir /dev/shm/gui_chroot 2>/dev/null
! mkdir /dev/shm/gui_chroot_backend 2>/dev/null

! umount /dev/shm/gui_chroot_backend
! umount /dev/shm/gui_chroot

mount -t tmpfs -o size=512m tmpfs /dev/shm/gui_chroot_backend

mkdir /dev/shm/gui_chroot_backend/work
mkdir /dev/shm/gui_chroot_backend/upper


mkdir /dev/shm/gui_chroot_backend/upper/run
mkdir /dev/shm/gui_chroot_backend/upper/dev
mkdir /dev/shm/gui_chroot_backend/upper/var
mkdir /dev/shm/gui_chroot_backend/upper/var/lock

mount --rbind /run /dev/shm/gui_chroot_backend/upper/run
mount --bind /dev /dev/shm/gui_chroot_backend/upper/dev

mount -t overlay overlay -o rw,lowerdir=/,upperdir=/dev/shm/gui_chroot_backend/upper,workdir=/dev/shm/gui_chroot_backend/work /dev/shm/gui_chroot



mount --rbind /var/lock /dev/shm/gui_chroot_backend/upper/var/lock

chroot /dev/shm/gui_chroot mount -o mode=755 -t proc proc  /proc
chroot /dev/shm/gui_chroot mount -o mode=755 -t sysfs sysfs /sys


mount -o bind /var/run/dbus /dev/shm/gui_chroot_backend/upper/run/dbus

! cp /home/daniel/.Xauthority /var/lock /dev/shm/gui_chroot_backend/upper/home/daniel/.Xauthority


! chroot /dev/shm/gui_chroot chromium-browser --no-sandbox --bwsi



umount /dev/shm/gui_chroot_backend/upper/run/dbus
umount /dev/shm/gui_chroot/sys
umount /dev/shm/gui_chroot/proc
umount /dev/shm/gui_chroot_backend/upper/var/lock
umount /dev/shm/gui_chroot
umount  /dev/shm/gui_chroot_backend/upper/dev
umount -lf /dev/shm/gui_chroot_backend/upper/run/
umount /dev/shm/gui_chroot_backend
