
#!/bin/bash

#All this does is makes the hostname configurable via /boot


unpack /filesystem/hostname.txt /boot/ root 
rm /etc/hostname
ln -s /boot/hostname.txt /etc/hostname
