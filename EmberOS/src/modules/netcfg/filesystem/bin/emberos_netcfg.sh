#!/bin/bash

#This script generates a yggdrasil config if it isn't there

#It also binds apache's www stuff
set -e

# if [ ! -f /sketch/config/yggdrasil.conf]; then
#     mkdir -p  /sketch/config/
#     yggdrasil -genconf -json >  /sketch/config/yggdrasil.conf
# fi
# mount --bind  /sketch/config/yggdrasil.conf /etc/yggdrasil.conf


update-ca-certificates

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

