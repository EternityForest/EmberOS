#!/bin/sh

#Embedtools replacement for hwclock-set on the raspberry pi

# Reset the System Clock to UTC if the hardware clock from which it
# was copied by the kernel was in localtime.

dev=$1


#We comment out the lines as per
#Many internet tutorials that have more info on why.

#We do this no matter what, since we get rid of systemd's time sync stuff
#Anyway in embedtools and replace it with ntp and custom scripts
#Otherwise, we just exit like usual on systemd

# if [ -e /run/systemd/system ] ; then
#     exit 0
# fi


if [ -e /run/udev/hwclock-set ]; then
    exit 0
fi

if [ -f /etc/default/rcS ] ; then
    . /etc/default/rcS
fi

# These defaults are user-overridable in /etc/default/hwclock
BADYEAR=no
HWCLOCKACCESS=yes
HWCLOCKPARS=
HCTOSYS_DEVICE=rtc0
if [ -f /etc/default/hwclock ] ; then
    . /etc/default/hwclock
fi


#We do our own system time to RTC stuff.
#Because I'd rather not set the RTC at all without first checking.

#I've commented out the systz lines as seems to be the preference of a lot 
#Of internet tutorials. Is this actually the best choice in the general case?
if [ yes = "$BADYEAR" ] ; then
    /bin/rtcsync.sh
    /sbin/hwclock --rtc=$dev --hctosys --badyear --adjfile=/var/run/rtc-adjfile
else
    /bin/rtcsync.sh
    /sbin/hwclock --rtc=$dev --hctosys --adjfile=/var/run/rtc-adjfile
fi

# Note 'touch' may not be available in initramfs
> /run/udev/hwclock-set
