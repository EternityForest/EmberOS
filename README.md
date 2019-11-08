# EmberOS

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
* Installs squid-deb-proxy-client to fetch updates from the LAN
* sets everything up for a realtime clock, just add dtoverlay
* Enables SSH, I2C, and SPI
* allows full configuration of SSH via the sketch partition

* Does NOT make the NTFS partition /sketch read only. You have to do that one yourself if you want it.

## Building(Need linux)

Clone this repo with all submodules

Put a fresh zipped raspbian full image in the src/images dir

Run sudo ./build_dist in the src dir. This may take about an hour, and 
you need internet access the whole time.

Cd into the src/workspace folder.
Expand the disk image by padding it with zeros:
Example:
`dd if=/dev/zero bs=1M count=7K >> 2019-06-20-raspbian-buster-full.img`
Change the filenames as neccesary. Count is in blocks. This appends about 8GB of extra space. You probably don't need this much.

You can also just shrink / to make room for the sketch partition


Mount the partition using `sudo udisksctl loop-setup -f 2019-06-20-raspbian-buster-full.img` 

Using your favorite partition editor, add an ntfs partition called sketch just after the root partition,
in that empty space you just made.

Copy everything in the root partition's sketch_template dir to the root of that partition.

## Squid Proxy

Thanks to the amazing squid-deb proxy, embedPiOs autodiscovers
package caches on the LAN!

Just install squid-deb-proxy on one machine, then add
```
mirrordirector.raspbian.org
archive.raspberrypi.org
```
to `/etc/squid-deb-proxy/mirror-dstdomain.acl`

to enable the rasbpian cache.

I suggest you set this up before building, as the cache should work
even during package build.


## Using an RTC
Add one of these lines to /boot/config.txt
```
dtoverlay=i2c-rtc,ds1307
dtoverlay=i2c-rtc,pcf8523
dtoverlay=i2c-rtc,ds3231
```

## Securing SSH

In /sketch/ssh/pi, you will find everything you might expect to see in ~/.ssh

You can add authorized keys there!

/sketch/ssh/ssh_config is equivalent to /etc/ssh_config.

Use this to disable password auth:
`PasswordAuthentication no`

There is no way to change the password for pi via the sketch folder,
however by disabling password auth, you can prevent anyone without physical access
from getting the chance to even try the password.



## Using

Change /sketch/hostname to the name you want to give it.  You can now access
it as hostname.local

Go to https://hostname.local:8001, and ignore the security warnings you will get(You're on a private network, right?)

You can now use it as any other Kaithem instance.  Look at the example module to get started.
Anything you create gets saved back to that /sketch partition.

If you need to "factory reset" an image, just delete and copy from sketch_template. 

If you need to update or install new software to the system itself, just SSH in and use
`sudo mount -o remount,rw /` to remount the root as writable, do your work, and reboot.



### Utils

This distro includes a lot of command line utils. If you are using this
over ssh from a windows machine, in a pinch you should be able to get whatever
you need to done.

#### ncdu
Interactive tool for figuring out what is taking all your space
`ncdu /folder/to/investigate`

#### nmap

#### micro
Awesome command line editor: https://micro-editor.github.io/

Pretty much like any normal editor, no crazy vim/emacs type
stuff to memorize here.  Everything is discoverable. Try it!


#### mc
Midnight commander. File manager with no learning curve.
Tab switches panes. The move command pops up a window
auto-filled with the other pane. It's pretty awesome.

`mc /folder/to/browse` or just `mc`

#### GNU Units
`units` to launch unit converions

#### xcas

Maybe controversial since it's 33MB,
but sometimes when developing you really need to solve an equation.

#### vim

I don't know how this works, but I work with people who would be dissapointed
if I didn't include it :P

#### chafa

`chafa FILE` views any kind of image file, in low res, in the
console.

#### git


#### ufw

Firewall. You might want this. But it is disabled by default.

#### robotfindskitten

Obviously the best console game :P

#### fortune
It's fortune!



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
