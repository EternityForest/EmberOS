#!/bin/bash

#This script generates a yggdrasil config if it isn't there

#It also binds apache's www stuff
set -e

# if [ ! -f /sketch/config/yggdrasil.conf]; then
#     mkdir -p  /sketch/config/
#     yggdrasil -genconf -json >  /sketch/config/yggdrasil.conf
# fi
# mount --bind  /sketch/config/yggdrasil.conf /etc/yggdrasil.conf


mkdir -p  /sketch/config/firewalld/
mount --bind  /sketch/config/firewalld/ /etc/firewalld/


# Keep this as is, because of the overlay, which we actually need because of dynamic regen
mkdir -p /dev/shm/etctmpssl
mkdir -p /dev/shm/etctmpssl_work

chmod 755 -R /dev/shm/etctmpssl
chmod 755 -R /dev/shm/etctmpssl_work

mount -t overlay -o lowerdir=/etc/ssl/certs,upperdir=/dev/shm/etctmpssl,workdir=/dev/shm/etctmpssl_work overlay /etc/ssl/certs

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
nss-systemcerts-import -d /home/pi/.pki/nssdb

