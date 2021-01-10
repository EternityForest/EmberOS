# EmberOS Help

## Removed packages

dillo, claws-mail, minecraft, mathematica, sonicpi, all but one version of Scratch, and several other apps have been removed. Most things have been replaced with more useful or more free equivalents.


## The command shell
We now use xonshell for the default shell. It is mostly bash compatible, but
also supports python. To use bash by default instead, do `chsh -s /bin/bash`

In addition, two BASIC interpreters are provided, brandy(BBC Basic V), which runs a graphical window, and  bwbasic, which can run in several modes.

## Getting online
Look in /sketch/networks, edit the wifi file as appropriate, or just connect ethernet.

These are NetworkManager files, so wifi will automatically reconnect for you, and you can configure almost any kind of network you want.

You can also go to the command line and use "nmtui" to connect.

## Chrome bookmarks

Chromium runs entirely in a RAM based folder, bookmarks are not persistant. This is because chrome
has a habit of heavy writes to disk, and EmberOS is designed for always-on kios style use.

However you can manually call save-chrominum-state to copy this to persistant storage.

You can also make ~/.config/chromium a symlink to a folder in persist, but that may wear out the SD card eventually.

## Media Streaming

All you need to do to enable using the Pi as a UPnP renderer is enable gmediarender in the autostart/99-defaults config file.  It will advertise itself
with whatever hostname you have selected.

## Making a backup

To pull everything on a remote EmberOS machine's sketch folder(Aside from things that are listed in the /sketch/.gitignore file),
use the tools/pullBack.sh script, and modify the hostname and password as needed.

Note that only the root .gitignore works for this, which is why the file comes preloaded with so many
entries.



## Making a server you can access from the internet

EmberOS includes HardlineP2P.  Put a file named WhateverName.ini in /sketch/config/hardline.services/, with content like:
https://github.com/EternityForest/hardlinep2p

```
[Service]
#The service you want to expose
service=localhost
port=80

#Use absolute paths for non-example applications. 
#The service file, and all it's associated files like the hash get created on-demand.
#Look in myservice.cert.hash to find the hash ID for the URL.
certfile=myservice.cert

[Info]
title="My Awesome Service"
```

Then (re)boot up, and visit  `hfhfdysvtziz6-e868423731872b8235a0adc9102bb45bb9e8321e.localhost:7009`(replace `hfhfdysvtziz6-e868423731872b8235a0adc9102bb45bb9e8321e` with your cert.hash file contents),
on any device with the HardlineP2P app enabled, including another EmberOS computer.  You may need to open port 7008 on your router, if it is missing UPnP, but you should see that service,
even offline.

Autostart/99-defaults.ini can be used to disable/enable hardline if needed.

Note that enabling any services will probably use 300MB-1GB per month of data due to OpenDHT being used, but a public DHT proxy is used if you're just accessing services.

Services still work on the LAN, even if you have no network access, and the technology does not use the blockchain.

### Android Apps

Look for HardlineP2P in the play store!

While installling apps from untrusted sources is considered a bad plan, the Hardlinep2p APKs are included in the sketch public data, in case you should find yourself without acccess to the play store,
and needing to configure a device.




## Offline Comms

A primary goal for EmberOS, although it is meant mostly as an embedded OS for "large" devices, is that in a pinch, if it is all you've got, you should be able
to cobble together whatever you need.

To that end, an unusually high number of communication options are included.

#### Mesh Networking

Yggdrasil is included, but not enabled by default.  You will need to add a few public peers to the configuration, or just let it autodiscover peers on the LAN.

The firewalld config blocks most incoming connections, including SSH, so you will need to change that.


#### Kouchat 

Provides a simple LAN chatroom, and is available on Android too. Drop a file
onto a username to share it. Text length is limited, but it is a very easy and
reliable choice.

#### Jami 
Provides decentralized chat, video, and file sharing. Recently, many features including group chat have been added. Android
is well supported. It is already configured for persistant storage.

Try this one!

#### Retroshare 

Provides decentralized forums, chat, and filesharing, and may be very useful in emergencies but is not available for Android. Start via the "compatibility mode"
shortcut. It is already configured for persistant storage.

As you must exchange keys with a peer to communicate, and they are too long for Kouchat's chat window, the recommemded way to bootstrap is to put your key in a file with mousepad, and share it via Kouchat.

The other option is to use Pidgin.

Once this is done, creating forums allows an experience not unlike BBS. Remember that messages will eventually disappear, unless you explicitly mark them to be saved
indefinately.

#### Pidgin

Provides the Bonjour LAN-only chat. This is a very common reliable choice that
is included with some distros, and also provides many other chat services including IRC. It is already configured for persistant storage.


#### Deluge

For sharing larger files, you will probably get better results just making a torrent, and sending the torrent file through Kouchat.

#### Dat

For sharing collections of files that can change over time, unlike fixed release torrents, we include Dat: https://docs.dat.foundation/
Dat requires some very basic command line use, but is near-ideal for publishing files, and for keeping things in sync with public files.

#### SyncThing

For 2-way sync between multiple machines, like keeping a music collection on a Kodi box in sync with a PC, there is SyncThing.


### The Home Dir and normal desktop use

/home/pi is in a tmpfs, but /home/pi/persist is bound to /sketch/home/pi, and anything in there is persistant.

The contents of /home/pi/persist/.home_template are copied to /home/pi after the tmpfs is mounted.

By default, many common folders that seem logical to assume you want persistant storage for are symlinked to the persist folder. ALWAYS CHECK BEFORE PUTTING IMPORTANT DATA SOMEWHERE!

DO NOT PUT ANYTHING YOU WANT TO KEEP IN THE ROOT OF THE HOME DIR!!!


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


#### Managing the certificate for Kaithem

Keys are generated automaticaly if the key(not the cert) is missing, and auto added to the browser trust.

The root CA that actually gets trusted is at /sketch/config/emberCA.pem,
And the key is at /sketch/config.private/emberCA.key

Delete both this key, and kaithem's key at /sketch/kaithem/ssl/certificate.key and reboot.

Then you will need to add the new key at /sketch/config/emberCA.pem to any browsers that need to be secure.

Of course, you can also manually supply these keys.

## Alternate shells
fish, elvish, bash, and xonsh are included.

### Setting bash back to default shell

`chsh -s $(which bash)`

## Enabling services

Instead of SSHing in(Which may not always be available), you can activate any systemd
service by editing the config files(See /sketch/config/autostart/).

They are very simple INI files.

You can't disable services enabled via systemctl this way(Under the hood, a script reads the file and starts all enabled services but does not sto anything).  The intent is to use the config files for all optional or user services.

## Sharing Files

Samba is enabled by default and exposes three shares. You can change any of this in
/sketch/config/smb.conf, which is just a standard samba config file.

### temp

This is readable and writable by anyone, however, it is a very small TMPFS, only useful
for quick and dirty sharing of non-private stuff under 32MB.  It is backed by the folder 
/public.temp, also readable by anyone.


### media

Used for media sharing, not writable from the network. Backed by /sketch/public.media(Bound to /var/public/media, which is readable by all and only writable by root).

There is a special subfolder called pi, which is bound to /home/pi/public.media, owned by pi, and readable to any.

### files

Used for general sharing, not writable from the network. Backed by /sketch/public.files(Bound to /var/public/files, which is readable by all and only writable by root).

There is a special subfolder called pi, which is bound to /home/pi/public.files, owned by pi, and readable to any.


## Educational Content/Offline resources

Several interesting PDFs, along with open source math, chemistry, and physics textbooks, are included. 

Low-resolution maps of the entire world are already included with Marble, which
is configured for persistent storage.

The wordnet dictionary, plus the GoldenDict viewer are included.


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

## Running a script without SSH

At boot, if there is a file named `/sketch/provisioning.sh`, it will be ran, then renamed to `/sketch/provisioning.sh.RAN`, and any output logged
to `/sketch/provisioning.sh.log`


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


### Firewalling

EmberOS uses firewalld.  

#### The Public Zone(Dofferent than the defaults!)
The ranges used by Yggdrasil and CJDNS are mapped to the public zone which blocks almost everything incoming, including SSH(Some other setups default to allowing SSH, we don't, because raspbian has a default password).

 Everything else is trusted by default.

#### Opening a port:
 firewall-cmd --permanent --zone=public --add-port=80/tcp

### Offline Wiki Content
Put any .zim files in a subfolder of /sketch/share/wikis/(One per subfolder).

You can then activate wikioffline@SUBFOLDER:PORT.service to serve that wiki on all IPv4 addresses.

The arch linux wiki will be included in the folder archlinux, so as to facilitate debugging 
when there is no internet connection.

This is provided by a small wrapper around ZIMPly.

You can also temporarily start the wiki server with `wikioffline SUBFOLDER PORT`

### Mesh Networks
In `/sketch/config/autostart/`, enable yggdrasil.service.

To configure it, see `/sketch/config.private/yggdrasil.conf`, which is mapped to the usual
`/etc/yggdrasil.conf` file. A sane default is provided with a generated unique private key.

You may then want to set up a NetworkManager file to use ad-hoc networking. Be sure to
set the firewalld zone to `public`, or else  ensure that you are not running anything private(Like ssh with weak passwords!!!)


### Configuring Audio

If you need to force HDMI or Analog output, or change the ALSA volume of the onboard card,
just edit /sketch/config/sound.ini, and change the output option to "hdmi" or "analog" as desired.

We default to "auto", which is probably not what you want if using an HDMI monitor and 3.5mm speakers.

This is provided by `ember-manage-audio.service`

## Serving OpenStreetMap Maps

Thanks to a symlink in /sketch/www, you can get map tiles at the url /maptiles/earth/openstreetmap/{z}/{x}/{y}.png if apache is enabled.

 The maps are stored at 
`/home/pi/.local/share/marble/maps/earth`, which is the same folder that marble. To get new maps, browse them in Marble,
or rsync from a laptop, they're all stored in .local/share in the same format and can just be copied over.

EmberOS includes maps of the entire world, at a fairly low resolution.



## Installing NextCloud

All dependancies should already be included, as is the zipped version of nexcloud itself.

You should be able to run `sh /usr/share.sketch/php_apps/install_nextcloud.sh`

.htaccess is already enabled, you shouldn't need anything else.

## Serving Media

One of the most common tasks for embedded devices is as a media server.
Put whatever you want to serve in /sketch/public.media for DLNA.

Put whatever you want to serve as a standard web site in /sketch/public.www to serve
it on port 80 with apache. Whatever you put as index.http will be the start page for the fullscren kiosk!  .htaccess files are already enabled.

Don't use the prefix "public." for anything you don't want to be made public, in case more
services are added!

This is provided by `minidlna.service` and can be disabled in the sketch autostart config.

## Adding programs to the sketch

The goal here is to be mostly batteries included, with a clean separation between your actual
application and the base image+packages, and usually you would just use "writable"
and then apt-get as normal if you need to install something.

However, /sketch/opt is bound to /sketch.opt, and /sketch/bin is bound to /usr/bin.sketch.

Both mapped views are mode 755 and root-owned.

Should you need something added to your path, and want to include it in the sketch, it is possible.


## Downloading/watching videos

Youtube-dl cannot be included, as APIs change so frequently that it would not do anyone any good.  However, you can use "sudo get-youtube-dl" to automatically get the latest version.

It will be stored in /sketch/bin, due ti the need for frequent easy updates(We consider it more like dynamic data than a real program, because of how often it updates).


## Media Center Use

Kodi is installed! See the KioskUI file, at the bottom there is an example of booting straight to it, which is recommended over the usual systemd way. You may need to manually set the audio output inside Kodi. It defaults to HDMI.

I suggest you get a 64GB or up SanDisk Industrial/Automotive/DVR grade SD
card if you want to use Kodi.

## Making it actually read only

You just add ro to the fstab entry for /sketch, that's the only writable part. You won't be
able to save without SSHing(Or using kaithem's terminal) and running `sudo mount -o remount,rw /sketch`.

NTFS is a journaling filesystem, so you may or may not actually need true read only. Some stuff may break if you do this.

Almost nothing ever writes to sketch randomly by itself, so it sould not cause disk wear.

## Updating Kaithem
The whole install as found in the repo is in /sketch/opt/kaithem.  Just
copy the entire contents of the repo there, or do a git pull --rebase right in that folder.

