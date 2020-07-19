#!/bin/bash

#Fix a bug where it sometimes seems to not
#Show up until you restart the process
#see https://bugs.launchpad.net/ubuntu/+source/avahi/+bug/624043
systemctl stop avahi-daemon.service
#Attempt to avoid race conditions with the previous iteration
sleep 3
systemctl restart avahi-daemon.service