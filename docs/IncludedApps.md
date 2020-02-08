### Automation Frameworks


#### Node Red
Already configured with symlinks for /home/pi. Just enable it in /sketch/config/autostart

#### Kaithem
The original purpose of the distro. /sketch/kaithem/ holds all the interesting
mutable state for easy deployment.  Just enable it in /sketch/config/autostart




### Apps

We include some useful GUI apps in addition to the raspbian stuff. Most are preconfigure
to persist user data(This is done by making the data folder a symlink into /home/pi/persist)

#### GIMP
#### SyncThing/SyncThing GTK
Already configured with symlinks for /home/pi, your config will
be persistentunder the pi user.

##### Remote Config:

Use this command on a Linux machine:
`ssh -L 9999:localhost:8384 HostName`

Ypu will then be able to access SyncThing's web GUI on local port 9999, which
tunnels to syncthing securely over SSH.

Or, "ssh -X" into the server, and just use the GTK GUI remotely.


#### Mednafen
Multi-emulator, already configured with symlinks for /home/pi

#### Tux Paint
Pictures folder is persistent
#### Sqlitebrowser
#### git-cola
#### Audacity
#### deluge
BT Client, .config/deluge is persistent
#### Ardour
.config/ardour5 is persistent

#### DosBox
.dosbox is persistent

#### Audacious

The suggested media player

#### Gnome Disk Util
The best partition manager, imager, and loop mounter. Run with gnome-disks

#### Calibre
EBook reader, server, and editor. Already set up with symlinks to /home/pi/persist

#### Zeal

Offline developer documentation browser. Docsets not included, but it's set up with symlinks to make them persistent.


### Languages
#### Elixir
Erlang-based language used in high reliability applications

#### Nim
New language with excellent C and python integration(Nimport is also included, to directly import from python)

#### PHP
Apache should be set up to use this already.

#### C/C++
G++, GCC, and build-essential are included, as is python3-dev

#### Elvish and Fish
Two alternative shells

#### Python3

### Libraries(Not a complete list)

#### Python3
* PyQt, QtWebKit, QtSvg, QtMultimedia




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

#### zile

Very small emacs clone 

#### chafa

`chafa FILE` views any kind of image file, in low res, in the
console.

#### git

#### nast

#### fatrace

#### htop


#### neofetch
All Arch Linux users are legally required to stare at this several times a day,
according to reddit memes.

Provides basic sys info with nice formatting.

#### robotfindskitten

Obviously the best console game :P

#### fortune
It's fortune!
