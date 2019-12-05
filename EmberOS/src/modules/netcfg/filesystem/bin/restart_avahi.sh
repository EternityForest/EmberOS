#!/bin/bash

#Fix a bug where it sometimes seems to not
#Show up until you restart the process
#see https://bugs.launchpad.net/ubuntu/+source/avahi/+bug/624043
systemctl restart avahi-daemon.service