# EmbedPiOS

This is a customPiOs tool for setting up a pi image suitable for consumer-grade embedded use. It runs the kaithem server as root on 8002, https 8001.

## Security

This is meant for easily creating embedded systems that run on *private* networks, in physically secure places(e.g. your house, where nobody
can tamper with the pi).

THE DEFAULT PASSWORD IS USED FOR KAITHEM, which runs as root. The standard pi:raspberry password is used.

Do *not* open a port to let people on the internet access this, without a firewall/nat/etc unless you change this.

Think of it like the common WiFi printers and file servers that allow anyone on the network to print.

### /sketch

To provide some semblance of security, umask is used to keep this from being read by anyone but root.

It is not encrypted though.

## What it does

* Adds a ntfs partition called /sketch  that is intended to be the storage location for everything except the os and libs
* Makes a file at /sketch/hostname.txt to let you change the hostname
* Installs chrony instead of garbage timesyncd
* Puts a whole bumch of tmpfses on things that write to disk, so they still work
* Generates entropy from the HW rnd on boot
* Makes sure avahi, exfat-utils, and other random stuff you probably want is installed
* Runs kaithem as root on port 8002(That's the kaithem module, you can easily swap this for some other control system)
* Makes /boot and / read-only

* Does NOT make the NTFS partition /sketch read only. You have to do that one yourself if you want it.

## Building(Need linux)

Clone this repo with all submodules

Put a fresh zipped raspbian full image in the src/images dir
Run sudo ./build_dist in the src dir!

Cd into the src/workspace folder.
Expand the disk image by padding it with zeros:
Example:
`dd if=/dev/zero bs=1M count=7K >> 2019-06-20-raspbian-buster-full.img`
Change the filenames as neccesary. Count is in blocks. This appends about 8GB of extra space.


Mount the partition using `sudo udisksctl loop-setup -f 2019-06-20-raspbian-buster-full.img` 

Using your favorite partition editor, add an ntfs partition called sketch just after the root partition,
in that empty space you just made.

Copy everything in the root partition's sketch_template dir to the root of that partition.

## Using

Change /sketch/hostname to the name you want to give it.  You can now access
it as hostname.local

Go to https://hostname.local:8001, and ignore the security warnings you will get(You're on a private network, right?)

You can now use it as any other Kaithem instance.  Look at the example module to get started.
Anything you create gets saved back to that /sketch partition.

If you need to "factory reset" an image, just delete and copy from sketch_template. 

If you need to update or install new software to the system itself, just SSH in and use
`sudo mount -o remount,rw /` to remount the root as writable, do your work, and reboot.



## Making it actually read only

You just add ro to the fstab entry for /sketch, that's the only writable part. You won't be
able to save without SSHing(Or using kaithem's terminal) and running `sudo mount -o remount,rw /sketch`.

NTFS is a journaling filesystem, so you may or may not actually need true read only.


## Kiosk browsering

Coming soon?

Warning: This script leaves bits of itself behind!! I'm leaving it here as a note to myself for
running chrome read only  without iverlayrooting the whole thing!!
```
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
```
