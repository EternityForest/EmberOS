# EmberOS Help

## Removed packages

dillo, claws-mail, minecraft, mathematica, sonicpi, Scratch, and several other apps have been removed. Most things have been replaced with more useful or more free equivalents.

## The Sketch Folder and the root

EmberOS uses a compressed readonly BTRFS filesystem for its root, both to be able to pack a lot of data, and to protect the root, so that you have 
a better chance of fixing things if anything goes wrong.

On top of that, we have a writable EXT4 overlay partition called /sketch.  This creates a clean separation and makes it easy to tell what has been
modified.  It also makes backups simpler.

We do not actually mount the overlay over /.  We mount it's individual folders over /bin, /opt.  So /sketch always reflets the real state of the persistent overlay, and there is no crazy recursive confusion.

## Ram Disk overlays

On top of that, we stack on some RAM disks for frequently written foldres to protect the SD card from wear and corruptions.

We do this with a bindings manager configured in /etc/fsbindings.




## The command shell
We now use xonshell for the default shell. It is mostly bash compatible, but
also supports python. To use bash by default instead, do `chsh -s /bin/bash`


## Getting online if you don't have a display for bootstrapping

We use NetworkManager here. You can easily set up Wifi just by editing files on the SD card.

Look in /etc/NetworkManager/networks, edit the wifi file as appropriate, or just connect ethernet.

You may need to install additional drivers to see this on Windows.

These are NetworkManager files, so wifi will automatically reconnect for you, and you can configure almost any kind of network you want.

Ignore all tutorials that mention wpa-supplicant or the like. You don't need to mess with that stuff.  Use "sudo nmtui" to
edit connections via the command line.

### Bootstrapping with ethernet

You could also just connect to pi to an ethernet hub and ssh into embedpi.local. Then you will be able to configure everything as normal.

## Media Streaming

All you need to do to enable using the Pi as a UPnP renderer is enable gmediarender in the autostart/99-defaults config file.  It will advertise itself with whatever hostname you have selected.



## Making a server you can access from the internet

EmberOS includes HardlineP2P.  Put a file named WhateverName.ini in /etc/hardline.services/, with content like:
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



#### Other user's home dirs

Other users home dirs won't be set up like /home/pi with protective ramdisks this unless you do it manually, EmberOS is mostly assuming  with Pi as the only non-system user.


## Alternate shells
fish, elvish, bash, and xonsh are included.

### Setting bash back to default shell

`chsh -s $(which bash)`

## Enabling services

Instead of SSHing in(Which may not always be available), you can activate any systemd
service by editing the config files(See /etc/ember-autostart/).

They are very simple INI files.

You can't disable services enabled via systemctl this way(Under the hood, a script reads the file and starts all enabled services but does not sto anything).

## Sharing Files

Samba is enabled by default and exposes three shares.

### temp

This is readable and writable by anyone, however, it is a very small TMPFS, only useful
for quick and dirty sharing of non-private stuff under 32MB.  It is backed by the folder 
/public.temp, also readable by anyone.


### media

Used for media sharing, not writable from the network. Backed by /var/public.media(which is readable by all and only writable by root).

There is a special subfolder called pi, which is bound to /home/pi/public.media, owned by pi, and readable to any.

### files

Used for general sharing, not writable from the network. Backed by /var/public.files(which is readable by all and only writable by root).

There is a special subfolder called pi, which is bound to /home/pi/public.files, owned by pi, and readable to any.


## Educational Content/Offline resources

Several interesting PDFs, along with open source math, chemistry, and physics textbooks, are included. 

Low-resolution maps of the entire world are already included with Marble, which
is configured for persistent storage.

The wordnet dictionary, plus the GoldenDict viewer are included.




## Changing the Kiosk UI

To run things at boot, just use .desktop files in /home/pi/.config/autostart

You can just modify the defaults to do what you want.




### Kaithem

Go to https://hostname.local:8001, and ignore the security warnings you will get(You're on a private network, right?)

You can now use it as any other Kaithem instance.  Look at the example module to get started.
Anything you create gets saved back to /home/pi/kaithem.


### Firewalling
mberOS uses firewalld.  

#### The Public Zone(Dofferent than the defaults!)
The ranges used by Yggdrasil and CJDNS are mapped to the public zone which blocks almost everything incoming, including SSH(Some other setups default to allowing SSH, we don't, because raspbian has a default password).

 Everything else is trusted by default.

#### Opening a port:
 firewall-cmd --permanent --zone=public --add-port=80/tcp

### Offline Wiki Content
Put any .zim files in a subfolder of /usr/share/zimwikis/(One per subfolder).

You can then activate wikioffline@SUBFOLDER:PORT.service to serve that wiki on all IPv4 addresses.

The arch linux wiki will be included in the folder archlinux, so as to facilitate debugging 
when there is no internet connection.

This is provided by a small wrapper around ZIMPly.

You can also temporarily start the wiki server with `wikioffline SUBFOLDER PORT`

### Mesh Networks
Enable yggdrasil.service.

You may then want to set up a NetworkManager file to use ad-hoc networking. Be sure to
set the firewalld zone to `public`, or else  ensure that you are not running anything private(Like ssh with weak passwords!!!)


## Serving OpenStreetMap Maps

You can get map tiles at the url /maptiles/earth/openstreetmap/{z}/{x}/{y}.png if apache is enabled, thanks to a symlink.

 The maps are stored at 
`/home/pi/.local/share/marble/maps/earth`, which is the same folder that marble. To get new maps, browse them in Marble,
or rsync from a laptop, they're all stored in .local/share in the same format and can just be copied over.

EmberOS includes maps of the entire world, at a fairly low resolution.




## Serving Media

One of the most common tasks for embedded devices is as a media server.
Put whatever you want to serve in /var/public.media for DLNA.

This is provided by `minidlna.service` and can be disabled in the sketch autostart config.

Apache is already set up and enabled out of the box.


## Updating Kaithem
The whole install as found in the repo is in /opt/kaithem.  Just do a git pull --rebase right in that folder.