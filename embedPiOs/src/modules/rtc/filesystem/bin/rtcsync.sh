#!/bin/bash

#Automatically keep the RTC in sync
#Only act if we have a configured RTC
if grep -q "i2c-rtc" /boot/config.txt; then
    #Try detecting Chrony
    if command -v chronyc; then
        if chronyc sources | grep -q "\^\*"; then
        #Using a temp file for that var run,
        #This will sadly mess with subsecond precision
        #across reboots though.

        #We really don't want to be writing to disk more than needed though.

        #I'm just going to assume though, that systems that need better precision
        #have a way of handling this, like staying synced to NTP.
        /sbin/hwclock -w --utc --adjfile=/var/run/rtc-adjfile
        fi
    fi


    #Now try the same thing, but with NTP
    if [[ ! -x /usr/bin/ntpstat ]]
    then
    exit 0
    fi


    res=$(/usr/bin/ntpstat)
    rc=$?

    case $rc in
    0 )
        #Clocks are synced
        /sbin/hwclock -w --utc --adjfile=/var/run/rtc-adjfile
        ;;
    1 )
        ;;
    2 )
        ;;
    esac

fi