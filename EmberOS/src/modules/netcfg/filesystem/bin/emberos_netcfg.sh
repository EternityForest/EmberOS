#!/bin/bash

#This script generates a yggdrasil config if it isn't there

#It also binds apache's www stuff
set -e

# if [ ! -f /sketch/config/yggdrasil.conf]; then
#     mkdirs -p  /sketch/config/
#     yggdrasil -genconf -json >  /sketch/config/yggdrasil.conf
# fi
# mount --bind  /sketch/config/yggdrasil.conf /etc/yggdrasil.conf


mkdirs -p  /sketch/firewalld/
mount --bind  /sketch/firewalld/ /etc/firewalld/
