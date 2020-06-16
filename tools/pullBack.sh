#!/bin/bash
set -e
set -x
#NOTICE: If this script randomly hangs, you probably have an invalid SSH cert for the remote host,
# Possibly because it's actually a different SD card with the same name. You need to run `ssh-keygen -R HOSTNAME` to clear
# this.

# You will probably also need to manually SSH to the server at least once, so that SSH has the key cached


#Change these to the server you want to back up.   Everything that isn't gitignored in the target's sketch folder will
#be backed up to a folder named sketch in the current directory.

export remoteServer=embedpi.local
export remoteLoginUser=pi


#The password used to log into the remote machine is read from the file ssh_password in the same dir as the script
export SSHPASS=raspberry

#########################################################################################################################
#Usage: pullFile /home/pi/foo.txt foo.txt
#Pulls one file on the remote to the local




#Now we use SSHPASS to log on, but after that we use sudo -S to elevate the rsync permissions, cat ing the password file we just made
function pullFile(){
    
    rsync --rsh="sshpass -e ssh -l $remoteLoginUser" -av --no-perms --no-owner --no-group $remoteLoginUser@$remoteServer:$1 $2
}

# Usage: pullWithIgnore /home/pi/foo/ foo/ ignore.conf
#Pull /home/pi/foo to local foo, using local ignore.conf file
function pullWithIgnore(){
    mkdir -p $2
    rsync --rsh="sshpass -e ssh -l $remoteLoginUser" -av --no-perms \
    --prune-empty-dirs --delete --no-owner --no-group \
    --exclude-from $3 $remoteLoginUser@$remoteServer:$1 $2
}


#Let pi see it with a bind mount
sshpass -e ssh $remoteLoginUser@$remoteServer  "mkdir -p /dev/shm/sketch_backup_mountpoint/"
sshpass -e ssh $remoteLoginUser@$remoteServer  "sudo bindfs -u $remoteLoginUser -p 0700 /sketch/ /dev/shm/sketch_backup_mountpoint/"

echo "setup session"

#First we grab the ignore file
pullFile /dev/shm/sketch_backup_mountpoint/.gitignore remoteIgnoreFile_autogen.txt
echo "got ignore file"
pullWithIgnore  /dev/shm/sketch_backup_mountpoint/ sketch/ remoteIgnoreFile_autogen.txt
echo "got sketch"

#Now get rid of that mountpoint
sshpass -e ssh $remoteLoginUser@$remoteServer "sudo umount /dev/shm/sketch_backup_mountpoint/ && rmdir /dev/shm/sketch_backup_mountpoint"
echo "Close session"

#rm sketch/kaithem/modules/1*
# Backup the boot stuff which is sometimes important
mkdir -p boot
pullFile /boot/config.txt boot/config.txt
pullFile /boot/cmdline.txt boot/cmdline.txt
echo "Got boot data"
