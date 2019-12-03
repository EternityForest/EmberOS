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

if [ ! -d /sketch/config/sslcerts ]; then
    mkdir -p /sketch/config/sslcerts
    cp  -La /etc/ssl/certs/. /sketch/config/sslcerts
fi


mkdir -p /dev/shm/etctmpssl
mkdir -p /dev/shm/etctmpssl_work

chmod 755 -R /dev/shm/etctmpssl
chmod 755 -R /dev/shm/etctmpssl_work

mount -t overlay -o lowerdir=/etc/ssl/certs,upperdir=/dev/shm/etctmpssl,workdir=/dev/shm/etctmpssl_work overlay /etc/ssl/certs

#Copy everything to the tmpfs from the sketch
cp  -a /sketch/config/sslcerts/. /etc/ssl/certs/
chmod 755 -R /etc/ssl/certs/


#Now update that cert bundle
update-ca-certificates &