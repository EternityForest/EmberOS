#!/bin/bash


#It also binds apache's www stuff
set -e

update-ca-certificates

! rm -r /home/pi/.pki/nssdb
#That should already by in a ramdisk
mkdir -p /home/pi/.pki/nssdb
chmod -R 755 /home/pi/.pki/nssdb
nss-systemcerts-import -d /home/pi/.pki/nssdb
chown -R pi /home/pi/.pki/nssdb

#This wipes out the system NSS config to setup the ramdisk.
#Which is file, the system cert bundle should be good.
mount -t tmpfs -o size=5m tmpfs /etc/pki/nssdb
chmod -R 755 /etc/pki/nssdb
nss-systemcerts-import -d /etc/pki/nssdb

