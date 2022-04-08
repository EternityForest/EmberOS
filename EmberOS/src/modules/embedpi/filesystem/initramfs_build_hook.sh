#!/bin/bash -e
# Environment variables are set by the calling script

set -e

# avoid running multiple times
if [ -n "$DEB_MAINT_PARAMS" ]; then
        eval set -- "$DEB_MAINT_PARAMS"
        if [ -z "$1" ] || [ "$1" != "configure" ]; then
                exit 0
        fi
fi



if [ -d "/lib/modules/$1" ]; then

    if [[ $1 == *\+ ]] # * is used for pattern matching
    then
        mkinitramfs -o "/boot/initramfs-emberos.gz" -k $1
    elif [[ $1 == *v7\+ ]] # * is used for pattern matching
    then
        mkinitramfs -o "/boot/initramfs-emberos-v7.gz" -k $1
    elif [[ $1 == *v7l\+ ]] # * is used for pattern matching
    then
        mkinitramfs -o "/boot/initramfs-emberos-v7l.gz" -k $1
    else
        echo "Don't know how to process that kernel"; 
    fi
else
    echo "File not found. it may be a big problem?"
fi
