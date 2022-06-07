![EmberOS](img/logo.webp)

This is a customPiOs distro for setting up a pi image suitable for consumer-grade embedded use, based on heaviliy modified Raspi OS.

This is a "batteries included" distro, meant to be usable in odd places when you might not
even have internet access. As such, it includes a lot of stuff.   It is available in two versions, MAX and Micro.

As another notable feature, the root filesystem uses BTRFS(Since the July 12 build), which allows us to compress things.  The root is read-only, but there is a third writable EXT4 partition called /sketch.

Overlay filesystems create the illusion that the whole thing is writable, so almost everything should look to a user just like vanilla raspbian.

*Also Important: There are no auto-updates, as they can cause stability issues, some applications may need to set that up.

See [Here](EmberOS/src/modules/embedpi/filesystem/public.files/emberos/ember-doc/README.md) for info on how to do common stuff.


## Ultra Quickstart

Flash the image.  You can now boot and use it like any other pi image, just a bit more hardened against SD wear.

You will need to make a new user following the new Pi foundation release,
you can do this with the pi imaging utility, or interactively when you first boot.  

Keep in mind some scripts out there may rely on the specific username "pi", so you might just want to keep that.

I think most stuff included with emberOS should be fine, but I'm not completely sure.


### How it works

EmberOS includes code(import_wpa_conf_to_nm.service) to import WLAN settings from wpa_supplicant if present, so the
existing Pi setup utilities should work.  We also patch the user config tools to properly modify lightdm's config, so autologin
works correctly.

### Setting stuff up by editing files

Set your computer up to be able to browse EXT4 partitions(On Linux this Just Works).  On Windows you
probably need extra software for this, or WSL2.  I don't know about Mac.

Look in the sketch partition. A few files are already present for maximally easy editing.  Fill in your wifi credentials in /etc/NetworkManager/system-connections if desired.

Set your new hostname in /etc/hostname/ and /etc/hosts/. Default is embedpi. 

Enable or disable any services you want in /etc/ember-autostart.  Note these are just systemd services, you could also
start them by command line, but this lets you do it purely with a text editor.

If you want to make a simple digital signage display, just put your stuff in /var/www/html/ starting at index.html and leave everything else alone, the default boot mode is to launch to a fullscreen chrome, set to not have any persistent state, so it won't wear things out.


## Home Assistant Warning

There are rumors that HA can be very hard on cards.  EmberOS will likely not be able to protect from this at all,
unless you are very careful with log settings.




## Debian 11 update, Kaithem does not run as root(2021Oct27 and up)

The system no longer uses Pulesaudio and Jack, it uses PipeWire which acts as a drop in replacement for those.

This is probably one of the biggest breaking changes ever. /home/pi/kaithem is bindfs linked to /sketch/kaithem and must be set as the site data dir.

You can still run it as root, but it will cause problems since the pi user owns PipeWire.

### Goals

* Reliable embedded control and digital signage
* Do almost anything offline once you have the image, most common tools included
* Usable for basic desktop tasks, if you're careful not to save stuff to volatile folders
* Declaratively configurable, you should be able to do almost everything just by editing files in /sketch
* As little configuration as possible for common tasks, everything should just work.
* Convenient platform for experimenting with your setup, includes all tools for minor tweaks to just about everything without needing a desktop computer.
* Things that require updates to keep working(Timezones, SSL, etc) are managed via /sketch for easy updates.
* Basically anything that's more of a "device" than a computer, that needs to be reliable and doesn't store too much data.
* Still fit on 8GB SD cards

![EmberOS](img/screenshot.webp)

### Use Cases

* Light duty embedded control/Home Automation(Kaithem or NodeRed)
* Digital Signage
* Offline Wiki Server
* Kiosk browser
* DLNA Media server/Samba fileserver/Web server/Torrent box
* Basic Desktop computer(If you are careful about the volatile home dir) 
* Realtime audio mixing with multiple soundcards(through Kaithem)
* Background Music player(Kaithem or Audacious)
* Amateur Radio station
* Mesh Networking node



#### Factory Reset

Because the root is read only, you can just wipe the /sketch partition, and you are good to go, back to a fresh start.
You will still need to recreate the empty /usr, /var, /etc, /opt, and /srv folders in /sketch.

As an easier way, just copy the contents of /boot/sketch.factory/


#### Storage Space
You deleting preinstalled things will not free up space, it will only put "whiteout" markers in the upper filesystem, actually using more space.  To actually gain space you would have to mount the card on a computer and remove stuff
from the underlying BTRFS partion, then expand /sketch to actually make use of it.

This has the notable disadvantage that when you update something, it will take up space as it cannot just remove the factory version.  This is less of an issue in the age of 16GB cards.

Due to the rather large base filesystem,  the sketch partition is pretty small, you will have to enlarge it yourself.

####  Other notes
It's important to note that nothing a device itself does modifies the base image, only the writable default.  By mounting on a host computer you could rsync them and delete the upper dir stuff to make your changes the new "factory defaults".

You can back up /sketch and be sure that you got all changes, with no factory stuff, but this method might not back up deletions to factory stuff, as those aren't real deletions.


## Security

Previously, SSL was enabled by default, and the default pi/raspberry account worked.

The pi foundation has changed this, and EmberOS's new goal is to mostly follow upstream. As such, you will need to create a user,
either interactively, by connection to a display and following prompts, or using the pi imaging tool.


There is also an unsecured Mosquitto MQTT server if you enable it, unlike the usual Mosquitto defaults.  On a private network
with non-critical info I think this is usually what you want

Also, the included SSL keys in /sketch/kaithem/ssl, and the SSH keys, are randomly generated on boot if missing.

They are just self signed keys though, you will get a warning in your browser.



## Prebuilt image

Builds are available as torrents only, and unless otherwise noted, may
go away when newer versions are released(My seedbox is fairly small!).

See the torrent files folder!

## Building(Need linux)

Clone this repo with all submodules.   Install eatmydata and duperemove.

Put a fresh zipped raspbian full image in the src/images dir

If you are starting from a 64 bit raspbian, you'll need to add export BASE_ARCH=aarch64 to config.

Run sudo eatmydata tmux -c ./build_dist in the src dir. This may take over an hour, and 
you need internet access the whole time, but almost all large downloads are cached between builds.

You will be asked two questions.  One is should non-superusers have access to AX25 ham radio interfaces, and another
is whether to use plugdev for solaar.  Answer yes to both

Eatmydata isn't necessary but speeds everything up a lot.  The tmux attempts protects your disk from 60GB of wear should the terminal log the output in a very inefficient way as some do.

Unpack latest Included Data torrent's sketch folder over to src/sketch_included_data/sketch.

Now run the postprocess_dist.sh script inside src.

You will find the postprocessed file in the workspace. You will then need to rename it to whatever you want, and you should
be ready to flash!

This image will be around 12GB.  To make a smaller one(It is exactly the same, just without the resource pack),
use the postprocess_dist_mini.sh instead. The resulting image will be 7.2GB.



### Apps
[See Here](docs/IncludedApps.md)


## Using an RTC
Add one of these lines to /boot/config.txt
```
dtoverlay=i2c-rtc,ds1307
dtoverlay=i2c-rtc,pcf8523
dtoverlay=i2c-rtc,ds3231
```
