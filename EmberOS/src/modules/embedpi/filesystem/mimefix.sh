set -e
set -x
umask 022 
update-mime-database /usr/share/mime
chmod -R o+r /usr/share/mime
