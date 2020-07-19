![EmberOS](img/logo.webp)

This is a customPiOs tool for setting up a pi image suitable for consumer-grade embedded use. 

It has a variety of preinstalled applications and can be configured almost entirely via a special windows-accessible /sketch partition.

Notably, everything except /sketch boots as read-only, and there is an Apache2 server and a chromium based kiosk browser enabled by default.

This is a "batteries included" distro, meant to be usable in odd places when you might not
even have internet access. As such, it includes a lot of stuff, and requires an 8GB card.

It would be possible to remove some things and shrink it, but I don't suggest this, as 
a 16GB card will make wear leveling more effective and give your app room to expand.

As a notable feature, the entire sketch partition is a Git repository, so you will
be able to track changes to the system(A sane .gitignore is included).


As another notable feature, the root filesystem uses BTRFS(Since the July 12 build), which allows us to compress things. BTRFS has a very high write amplification,
so I don't suggest using it on SD cards in non-mostly-readonly configurations, however it should not be a problem for this.


*Important: If you ever update the kernel, you have to run* `mkinitramfs -o /boot/initramfs-emberos.gz`

See [Here](EmberOS/src/modules/embedpi/filesystem/sketch/public.files/emberos/ember-doc/README.md) for info on how to do common stuff.

### Goals

* Reliable embedded control and digital signage
* Do almost anything offline once you have the image, most common tools included
* Usable for basic desktop tasks, if you're careful not to save stuff to volatile folders
* Declaratively configurable, you should be able to do almost everything just by editing files in /sketch
* As little configuration as possible for common tasks, everything should just work.
* Convenient platform for experimenting with your setup, includes all tools for minor tweaks to just about everything without needing a desktop computer.
* Things that require updates to keep working(Timezones, SSL, etc) are managed via /sketch for easy updates.

* Basically anything that's more of a "device" than a computer, that needs to be reliable and doesn't store too much data.

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


#### Semi read only
 Read only root filesystem, and mostly read only /home/pi, with carefully controlled symlinks to persistent folders to make apps work as they should, while keeping everything
 else read only, or purely volatile, so things like chromium's absurd disk writes can't cause trouble.



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



### Changing the passwords
At the moment, users and passwords are stored in their normal place.  /sketch is mostly for the things one might want under version control, to deploy repeatedly, or the stuff you might
want to chage really quickly for basic non-critical non-secure use.

I might move /etc/shadow, but for now just do `writable` then change passwords in the usual way, the users aren't exactly part of the "application data" anyway.


### /sketch

To provide some semblance of security, umask is used to keep this from being accessed by anyone but root.
It can be read and executed by root's group, but only written by root itself, aside from via BindFS.

It is not encrypted though.


## Prebuilt image

Builds are available as torrents only, and unless otherwise noted, may
go away when newer versions are released(My seedbox is fairly small!).

See the torrent files folder!

## Building(Need linux)

Clone this repo with all submodules

Put a fresh zipped raspbian full image in the src/images dir

Run sudo ./build_dist in the src dir. This may take over an hour, and 
you need internet access the whole time.


Unpack latest Included Data torrent's sketch folder over to src/sketch_included_data/sketch.

Now run the postprocess script inside src.

You will find the postprocessed file in the workspace. You will then need to rename it to whatever you want, and you should
be ready to flash!


### The Bindings Manager

More documentation to come, but basically, everything is managed via
a "bind engine" that takes config files and uses them to set up bindings
between /sketch and other places.

BindFS allows permission-transformed views, which is how other users can write to selected dirs in /sketch, which is normally owned by root with mode 700.

The binding manager runs once at boot.

This is what config files look like:

```yaml
cat << EOF > /sketch/config/filesystem/some_directory.yaml
/sketch/foo:
    #Mode must be quoted
    mode: '0755'
    #/var/lib/someApplication and all files under
    #it appear to be owned by root
    user: root
    #Binds /sketch/home/foo to /var/lib/someApplication
    bindat: /var/lib/someApplication
    pre_cmd: echo beforemainbindmount
    post_cmd: echo aftermainbindmount
    #This binds /var/lib/someApplication/foo to /etc/foo
    bindfiles:
        foo: /etc/foo
```
This is managed by `fs_bindings.service`

### Apps
[See Here](docs/IncludedApps.md)


## Using an RTC
Add one of these lines to /boot/config.txt
```
dtoverlay=i2c-rtc,ds1307
dtoverlay=i2c-rtc,pcf8523
dtoverlay=i2c-rtc,ds3231
```
