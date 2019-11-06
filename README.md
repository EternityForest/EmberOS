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
* Generates entropy from the HW 
* Makes sure avahi, exfat-utils, and other random stuff you probably want is installed
* Runs kaithem as root on port 8002(That's the kaithem module)
* Makes /boot and / read-only

* Does NOT make the NTFS partition /sketch read only. You have to do that one yourself if you want it.

## Building(Need linux)

Expand the SD cart to make room for the extra stuff we're about to install
dd if=/dev/zero bs=1M count=7K >> IMAGEFILE

Mount a fresh raspbian image as a loopback device(sudo udisksctl loop-setup -f IMAGEFILE)

Using a partition manager(gnome-disks works best)
add another partition to the file. Call it "sketch", 

Expand by at least 500MB to keep customPiOs happy, bt really you should probably expand by 2GB or so.

Sketch must be an NTFS partition.

Unmount the loop dev(Minus icon in gnome-disks)

Put the file back in a.zip with the same-ish name pattern that customPiOs needs, and put it in the src/image dir.

Run sudo ./build_dist in the src dir!

Find your shiny new image in the workspace folder


## Making it actually read only

You just add ro to the kernel command line and the fstab. Everything else is already there, all the tmpfses are set up.
