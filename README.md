![EmberOS](img/logo.webp)

This is a customPiOs tool for setting up a pi image suitable for consumer-grade embedded use. 

It has a variety of preinstalled applications and can be configured almost entirely via a special windows-accessible /sketch partition.

Notably, everything except /sketch boots as read-only, and there is an Apache2 server and a chromium based kiosk browser enabled by default.

This is a "batteries included" distro, meant to be usable in odd places when you might not
even have internet access. As such, it includes a lot of stuff and requires a 16GB card(The image is just under 9GB min, including 1024MB of free space on root.)

It would be possible to remove some things and shrink it, but I don't suggest this, as 
a 16GB card will make wear leveling more effective and give your app room to expand.


## Enabling services

Instead of SSHing in(Which may not always be available), you can activate any systemd
service by editing the config files(See /sketch/config/autostart/).

They are very simple INI files.

You can't disable services enabled via systemctl this way(Under the hood, a script reads the file and starts all enabled services but does not sto anything).  The intent is to use the config files for all optional or user services.

## Provisioning.sh

At boot, if there is a file named /sketch/provisioning.sh, it will be ran, then renamed to /sketch/provisioning.sh.RAN, and any output logged
to /sketch/provisioning.sh.log


## Security

This is meant for easily creating embedded systems that run on *private* networks, in physically secure places(e.g. your house, where nobody
can tamper with the pi).

THE DEFAULT PASSWORD IS USED FOR KAITHEM, which runs as root. The standard pi:raspberry password is used for SSH.

Do *not* open a port to let people on the internet access this, 
without a firewall/nat/etc unless you change this, or disable password auth(Probably the better option)

There is also an unsecured Mosquitto MQTT server. Nothing is currently using it, but if you
do, be sure nobody can access those ports. 


Think of it like the common WiFi printers and file servers that allow anyone on the network to print.

Also, the included SSL keys in /sketch/kaithem/ssl, and the SSH keys, are randomly generated on boot if missing.

They are just self signed keys though, you will get a warning in your browser.




### /sketch

To provide some semblance of security, umask is used to keep this from being accessed by anyone but root.
It can be read and executed by root's group, but only written by root itself, aside from via BindFS.

It is not encrypted though.

## What it does

* Adds a ntfs partition called /sketch  that is intended to be the storage location for everything except the os and libs. It is owned by root with mode 750, so not just any random
process can access it. For this reason a lot of it's data is copied to /tmp at boot


* Makes a file at /sketch/config/hostname to let you change the hostname
* Hostsfile is now at /sketch/config/hosts
* Installs chrony instead of garbage timesyncd
* Puts a whole bunch of tmpfses on things that write to disk, so they still work
* Generates entropy from the HW rnd on boot
* Makes sure avahi, exfat-utils, and other random stuff you probably want is installed
* Runs kaithem as root, if kaithem.service is enabled in the autostart config
* Runs node-red as root, if the service is enabled in the autostart config
* Makes /boot and / read-only
* Sets everything up for a realtime clock, just add dtoverlay
* Enables SSH, I2C, and SPI, and the camera interface
* Allows full configuration of SSH via the sketch partition
* Installs Samba and DLNA(Not enabled by default)
* Puts a tmpfs over /home/pi and /root, making them volatile but writable.
* BindFS binds /home/pi/persist to the /sketch/home/pi, allowing persistent user data
* Disables overscan. You almost certainly don't want this on a modern display.
* Sets up a US keyboard layout(This will eventually be set through /sketch if there's interest)
* Boots by default into a Chromium fullscreen kiosk(Exit with alt-f4) pointed at http://localhost

* Allows configuring NetworkManager via /sketch/networks

* Does NOT make the NTFS partition /sketch read only. You have to do that one yourself if you want it, and some things assume it is writable.

* Sets up firewalld, but the default zone is trusted, so it does nothing until you configure it, aside from making the Yggdrasil and CJDNS IP ranges untrusted

* Symlink Documents, Downloads,Pictures, Arduino, Templates,Music, and Videos to ~/persist
* Share /home/pi/SharedMedia via DLNA

## Prebuilt image

Builds are available as torrents only, and unless otherwise noted, may
go away when newer versions are released(My seedbox is fairly small!).

### Dec 07 2019 alpha build

magnet:?xt=urn:btih:43679a8e9597c89a6f68612bb57e9169a662b44c&dn=2019Dec7EmberOS.zip&tr=udp%3a%2f%2ftracker.leechers-paradise.org%3a6969&tr=udp%3a%2f%2ftracker.coppersurfer.tk%3a6969&tr=udp%3a%2f%2fopen.demonii.com%3a1337&tr=udp%3a%2f%2ftracker.pomf.se&tr=udp%3a%2f%2fexodus.desync.com%3a6969&x.pe=97.126.96.222:44319&x.pe=[2602:61:7e60:de00:30e5:5f70:3d00:4bbd]:44319&x.pe=[fd00::95f1:a94c:35be:32ff]:44319&x.pe=[2602:61:7e60:de00:b095:fd54:f0dc:1c3c]:44319&x.pe=[fd00::b095:fd54:f0dc:1c3c]:44319&x.pe=[fd00::d83c:8af6:9c12:cdec]:44319&x.pe=[200:615:1617:bc9f:9ae8:14fe:2673:10c0]:44319&x.pe=[2602:61:7e60:de00:d83c:8af6:9c12:cdec]:44319

## Building(Need linux)

Clone this repo with all submodules

Put a fresh zipped raspbian full image in the src/images dir

Run sudo ./build_dist in the src dir. This may take about an hour, and 
you need internet access the whole time. It is not fully scripted, at one point samba will ask to modify
the config file. You should say yes.


Cd into the src/workspace folder.
Expand the disk image by padding it with zeros:
Example:
`dd if=/dev/zero bs=1M count=1K >> 2019-06-20-raspbian-buster-full.img`
Change the filenames as neccesary. Count is in blocks. This appends about 1GB of extra space. You probably don't need this much.

You can also just shrink / to make room for the sketch partition.  You may want to keep it small for 8GB sd cards


Mount the partition using `sudo udisksctl loop-setup -f 2019-06-20-raspbian-buster-full.img` 

Using your favorite partition editor, add an ntfs partition called sketch just after the root partition,
in that empty space you just made.

Copy everything in the root partition's sketch dir to the root of that partition.  Anything
in the actual sketch dir is just the default, it gets covered over by the sketch partition that gets mounted there.

If your image is for systems with an RTC, see "using an RTC"

## Using an RTC
Add one of these lines to /boot/config.txt
```
dtoverlay=i2c-rtc,ds1307
dtoverlay=i2c-rtc,pcf8523
dtoverlay=i2c-rtc,ds3231
```

## Getting online
Look in /sketch/networks, edit the wifi file as appropriate, or just connect ethernet.

## Securing SSH

In /sketch/ssh/pi, you will find everything you might expect to see in ~/.ssh

You can add authorized keys there, same as you would in .ssh on any machine!

/sketch/ssh/ssh_config is equivalent to /etc/ssh_config.

Use this to disable password auth:
`PasswordAuthentication no`

There is no way to change the password for pi via the sketch folder,
however by disabling password auth, you can prevent anyone without physical access
from getting the chance to even try the password.

If you want to allow root login(May be needed for SFTP clients), use:
`PermitRootLogin yes`

And add the keys to /sketch/ssh/root/


## Changing the Kiosk UI

Everything is defines in /sketch/kioskUI.conf, a standard FVWM config file that launches fullscreen chrome by default, but can be customized
to do just about anything.

Look at the very bottom for the lines that deal with launching apps.

## Changing the timezone
/sketch/timezone is a text file that should just contain an Olson timezone name like "Us/Pacific" without quotes.

## Using

Change /sketch/hostname to the name you want to give it.  You can now access
it as hostname.local

If you need to "factory reset" an image, just delete and copy from rootfs /sketch to the sketch partition. 

If you need to update or install new software to the system itself, just SSH in and use
`sudo mount -o remount,rw /` to remount the root as writable, do your work, and reboot.

Note that this won't affect home dirs, they have a separate tmpfs.


### Kaithem

Go to https://hostname.local:8001, and ignore the security warnings you will get(You're on a private network, right?)

You can now use it as any other Kaithem instance.  Look at the example module to get started.
Anything you create gets saved back to that /sketch partition.


### The Home Dir and normal desktop use

/home/pi is in a tmpfs, but /home/pi/persist is bound to /sketch/home/pi, and anything in there is persistant.

The contents of /home/pi/persist/.home_template are copied to /home/pi after the tmpfs is mounted.

By default, many common folders that seem logical to assume you want persistant storage for
are symlinked to the persist folder. ALWAYS CHECK BEFORE PUTTING IMPORTANT DATA SOMEWHERE!

#### Adding a persisant directory/customizing the home dir
```
#Create the actual persistant directory
mkdir persist/foo

#Now create a link to it. You can't just put it in the home dir directly,
#As that is just a tmpfs

#So you add it to the .home_template, which is copied to home on boot.
ln -s persist/foo .home_template/foo
```

#### Other user's home dirs

Other users home dirs won't be set up like this unless you do it manually, EmberOS is mostly assuming  with Pi as the only non-system user.


### Firewalling

EmberOS uses firewalld.  The ranges used by Yggdrasil and CJDNS are mapped to the public zone which blocks almost everything incoming,
including SSH(Some other setups default to allowing SSH, we don't, because raspbian has a default password). Everything else is trusted by default.

#### Opening a port:
 firewall-cmd --permanent --zone=public --add-port=80/tcp


### Configuring Audio

If you need to force HDMI or Analog output, or change the ALSA volume of the onboard card,
just edit /sketch/config/sound.ini, and change the output option to "hdmi" or "analog" as desired.

We default to "auto", which is probably not what you want if using an HDMI monitor and 3.5mm speakers.

### Apps
(See apps listing)[docs/IncludedApps.md]

## Serving Media

One of the most common tasks for embedded devices is as a media server.
Put whatever you want to serve in /sketch/public.media for DLNA,
/sketch/public.files for samba.

Put whatever you want to serve as a standard web site in /sketch/public.www to serve
it on port 80 with apache. Whatever you put as index.http will be the start page for the fullscren kiosk!

Don't use the prefix public. for anything you don't want to be made public in case more
services are added!

## Making it actually read only

You just add ro to the fstab entry for /sketch, that's the only writable part. You won't be
able to save without SSHing(Or using kaithem's terminal) and running `sudo mount -o remount,rw /sketch`.

NTFS is a journaling filesystem, so you may or may not actually need true read only.

## Updating Kaithem
The whole install as found in the repo is in /sketch/opt/kaithem.  Just
copy the entire contents of the repo there.

