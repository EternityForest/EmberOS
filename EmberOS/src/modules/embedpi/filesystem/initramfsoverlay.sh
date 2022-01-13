#!/bin/sh

rescue_shell() {
    echo "Something went wrong. Dropping to a shell."
    exec sh
}

PREREQ=""
prereqs()
{
   echo "$PREREQ"
}

case $1 in
prereqs)
   prereqs
   exit 0
   ;;
esac

. /scripts/functions

# Mount the /proc and /sys filesystems.
mount -t proc none /proc
mount -t sysfs none /sys

# Do your stuff here.
echo "EmberOS Initramfs running!"

fsck -p UUID=33fc23d5-a31d-45ed-8aec-e85f4fb4a436

# Ember Raw Mode prevents the upper overlay.
# We run directly on the writable root lower dir.



# This is used for customizing an image.
if [ -f ${rootmnt}/ember-raw-mode ]; then
    mount -o remount,rw ${rootmnt} || rescue_shell

else
    # Mount the Sketch Partition. Should we fail to do this, we go to recovery mode.
    if mount -t ext4,btrfs,f2fs -o ro,noatime UUID=c8dd1d93-222c-42e5-9b03-82c24d2433fd ${rootmnt}/sketch ; then


        # We have a file to trigger menu loading, otherwise we use the load profile file
        if [ -f ${rootmnt}/sketch/show-menu ]; then
            SELECTEDPROFILE=$(dialog --dselect ${rootmnt}/sketch/profiles/default 25 25  --output-fd 1)
        else
            SELECTEDPROFILE=`cat ${rootmnt}/sketch/load-profile`
        fi

        # This is a special option just for dropping right into the raw base BTRFS image.
        if [ "$SELECTEDPROFILE" = "__raw_base_image__" ]; then
          mount -o remount,rw ${rootmnt} || rescue_shell
        else
            SELECTEDPROFILE = ${rootmnt}/sketch/profiles/$SELECTEDPROFILE
            # We have a special flag that makes a profile 100% volatile
            if [ -f ${SELECTEDPROFILE}/volatile-overlay ]; then
                echo "Volatile profile"
            else
                mount -o remount,rw,noatime ${rootmnt}/sketch
        
            
                mkdir -p "${SELECTEDPROFILE}"


                # Make the individial mounts.  Note that we do not overlay the whole root.  That wold do some recursion loop business that would be confusing, and we need to always be able to see what's in /sketch
                # We have tmpfses but those come later, after this.
                
                # Note that we mkdir here because the user could make a new profile right in the initramfs
                # We can't do that on a volatle profile though
                mkdir -p "${SELECTEDPROFILE}/etc/"
                mkdir -p "${SELECTEDPROFILE}/srv/"
                mkdir -p "${SELECTEDPROFILE}/opt/"
                mkdir -p "${SELECTEDPROFILE}/home/"
                mkdir -p "${SELECTEDPROFILE}/usr/"
                mkdir -p "${SELECTEDPROFILE}/var/"


                mkdir -p "${SELECTEDPROFILE}/.overlay_work/etc"
                mkdir -p "${SELECTEDPROFILE}/.overlay_work/srv"
                mkdir -p "${SELECTEDPROFILE}/.overlay_work/usr"
                mkdir -p "${SELECTEDPROFILE}/.overlay_work/opt"
                mkdir -p "${SELECTEDPROFILE}/.overlay_work/home"
                mkdir -p "${SELECTEDPROFILE}/.overlay_work/var"
            fi

            mount -t overlay overlay -o "lowerdir=${rootmnt}/etc,upperdir=${SELECTEDPROFILE}/etc/,workdir=${SELECTEDPROFILE}/.overlay_work/etc" ${rootmnt}/etc/ || rescue_shell
            mount -t overlay overlay -o "lowerdir=${rootmnt}/var,upperdir=${SELECTEDPROFILE}/var/,workdir=${SELECTEDPROFILE}/.overlay_work/var" ${rootmnt}/var/ || rescue_shell
            mount -t overlay overlay -o "lowerdir=${rootmnt}/usr,upperdir=${SELECTEDPROFILE}/usr/,workdir=${SELECTEDPROFILE}/.overlay_work/usr" ${rootmnt}/usr/ || rescue_shell
            mount -t overlay overlay -o "lowerdir=${rootmnt}/opt,upperdir=${SELECTEDPROFILE}/opt/,workdir=${SELECTEDPROFILE}/.overlay_work/opt" ${rootmnt}/opt/ || rescue_shell
            mount -t overlay overlay -o "lowerdir=${rootmnt}/srv,upperdir=${SELECTEDPROFILE}/srv/,workdir=${SELECTEDPROFILE}/.overlay_work/srv" ${rootmnt}/srv/ || rescue_shell
            mount -t overlay overlay -o "lowerdir=${rootmnt}/home,upperdir=${SELECTEDPROFILE}/home/,workdir=${SELECTEDPROFILE}/.overlay_work/home" ${rootmnt}/home/ || rescue_shell
        
            
            # We have a special flag that makes a profile 100% volatile
            if [ -f ${SELECTEDPROFILE}/volatile-overlay ]; then
                mkdir -p /overlay
                mount -t tmpfs tmpfs /overlay
                mkdir -p /overlay/upper
                mkdir -p /overlay/work
                mkdir -p /overlay/lower
                mount -t overlay overlay -olowerdir=/overlay/lower,upperdir=/overlay/upper,workdir=/overlay/work ${rootmnt}
            fi

            # Another special flag lets us define profile-specific initramfs loading.
            if [ -f ${SELECTEDPROFILE}/initramfs-script ]; then
                ash ${SELECTEDPROFILE}/initramfs-script
            fi
        
        fi
    else
        echo "You have encountered a bad problem and will probably not go to space today"
    fi

fi