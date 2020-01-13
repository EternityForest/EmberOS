
# The Sketch Filesystem Standard

Note that NTFS is not using real permissions, every folder is owned by root, but they are BindFSed to different
places with different permissions.

## Per user stuff

Note that only pi actually is set up this way.

### /sketch/home/USER
Maps to /home/USER/persist. By default mode 750.

Only for manually created data like LibreOffice documents. Should not contain .config or anything like that
which is likely to be messed with automatically and wear the card out

### /sketch/home/USER/.home_template/
Gets copied to the root of the user's home, letting you set it up how you like it

### /sketch/ssh/USER/
The SSH dir for a user. Mode 700. This mode difference is why we don't use persist.

## System level stuff 

### /sketch/config/
Roughly equivalent to /etc/ but ONLY for non-secret data. Mode 755.

### /sketch/config/sslcerts.local
Any cert here is automatically trusted

### /sketch/config/sslcerts
Trusted ssl certs

### /sketch/config/ca-certificates.conf
Configures which certs in /sketch/config/sslcerts to trust and distrust.
Equivalent to /etc//ca-certificates.conf



### /sketch/cache/
Roughly /var/cache, but not a direct binding, only certain subfolders have bindings.


## Sharing 

### /sketch/public.media
Things to DLNA share with the local network
Bound to /var/public.media 755

#### /sketch/public.media/pi
Bound to /home/pi/PublicMedia

### /sketch/public.files
Files to samba, etc share
Bound to /var/public.files

#### /sketch/public.files/pi
Bound to /home/pi/PublicFiles

### /sketch/public.www
The Apache webserver. It's 755 owned by www-data,
so 