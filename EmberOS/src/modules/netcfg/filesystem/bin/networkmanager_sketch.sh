#!/bin/bash

mkdir -p /dev/shm/nmsketch
cp -ar /sketch/networks/. /dev/shm/nmsketch

#NM has a fit if the file is writabl by root group
chmod -R 600 /dev/shm/nmsketch

# Use the sketch's networks
mount --bind /dev/shm/nmsketch /etc/NetworkManager/system-connections
