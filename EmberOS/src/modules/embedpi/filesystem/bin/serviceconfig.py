#!/usr/bin/python3


SYSTEMD_DEST = "/run/systemd/transient"

SKETCH_CONFIG = "/etc/ember-autostart"

import os,shutil,configparser,subprocess,traceback

config = configparser.ConfigParser()


for i in sorted(list(os.listdir(SKETCH_CONFIG)), reverse=True):
    if i.endswith(".ini") or i.endswith(".conf"):
        config.read(os.path.join(SKETCH_CONFIG,i))

#Start all the services listed in the config

#For now, let's not allow disabling anything at runtime
#That might cause issues if they were already enabled.
s=[]
if 'units' in config:
    for i in config['units']:
        if config['units'][i].lower() in ("enable","true","yes","enabled"):
            s.append(i)
            print("Enabled:"+i)

#Start all as one transaction
try:
    subprocess.call(["systemctl","start"]+s)
except:
    print(traceback.format_exc())
