#!/bin/bash


#It also binds apache's www stuff
set -e



#Put everything in oe folder and hash it all, so that we can detect changes.
mkdir /dev/shm/emberssl
rsync -az /sketch/config/sslcerts/ /dev/shm/emberssl/
rsync -az /sketch/config/sslcerts.local/ /dev/shm/emberssl/
rsync -az /sketch/config/ca-certificates.conf /dev/shm/emberssl/

find /dev/shm/emberssl -type f -exec md5sum {} \; | sort -k 2 | md5sum > /dev/shm/emberssl.hash

rm -rf /dev/shm/emberssl/

#If the hash doesn't match what we have
if ! cmp /dev/shm/emberssl.hash /sketch/.emberos/cache/ssl_tar_md5 >/dev/null 2>&1
then
    update-ca-certificates

    #That should already by in a ramdisk
    mkdir -p /home/pi/.pki/nssdb

    #This wipes out the system NSS config to setup the ramdisk.
    #Which is file, the system cert bundle should be good.
    mount -t tmpfs -o size=5m tmpfs /etc/pki/nssdb
    chmod -R 755 /etc/pki/nssdb
    nss-systemcerts-import -d /etc/pki/nssdb

    mount -t tmpfs -o size=5m tmpfs /home/pi/.pki/nssdb
    rsync -az /etc/pki/nssdb/ /home/pi/.pki/nssdb

    chmod -R 755 /home/pi/.pki/nssdb
    chown -R pi /home/pi/.pki/nssdb

    mkdir -p /sketch/.emberos/cache/etc.ssl/
    mkdir -p /sketch/.emberos/cache/etc.pki.nssdb/
    
    #Copy over our cache
    rsync -az /etc/ssl/certs/ /sketch/.emberos/cache/etc.ssl
    rsync -az /etc/pki/nssdb/ /sketch/.emberos/cache/etc.pki.nssdb/

    #Set flag so we don't redo this
    mv /dev/shm/emberssl.hash /sketch/.emberos/cache/ssl_tar_md5
else

    #They are the same
    rm /dev/shm/emberssl.hash

    #Load from 
    mount -t tmpfs -o size=5m tmpfs /etc/pki/nssdb
    chmod -R 755 /etc/pki/nssdb
    mount -t tmpfs -o size=5m tmpfs /home/pi/.pki/nssdb
    chown -R pi /home/pi/.pki/nssdb/

    #Use the cache
    rsync -az /sketch/.emberos/cache/etc.ssl/ /etc/ssl/certs/
    rsync -az /sketch/.emberos/cache/etc.pki.nssdb/ /etc/pki/nssdb/
    rsync -az /etc/pki/nssdb/ /home/pi/.pki/nssdb
fi

