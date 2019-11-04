# EmbedPiOS

This is a customPiOs tool for setting up a pi image suitable for embedded use.

WIP, don't use yet

## What it does

* Makes a file in /boot/hostname.txt to change the hostname
* Installs chrony instead of garbage timesyncd
* Puts a whole bumch of tmpfses on things that write to disk, doesn't actually make anything read only, just writes less
* Generates entropy from the HW 
* Makes sure avahi, exfat-utils, and other random stuff you probably want is installed


## Making it actually read only

You just add ro to the kernel command line and the fstab. Everything else is already there, all the tmpfses are set up.
