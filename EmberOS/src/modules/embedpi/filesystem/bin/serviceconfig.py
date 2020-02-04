#!/usr/bin/python3


SYSTEMD_DEST = "/run/systemd/transient"
SKETCH_UNITS = "/sketch/config/systemd"

SKETCH_CONFIG = "/sketch/config/startup"

import os,shutil,configparser,subprocess

config = configparser.ConfigParser()

#Copy any files sketch-provided unit files
for i in sorted(os.listdir(SKETCH_UNITS)):
    #Filter stuff that shouldn't be there
    if not (i.endswith(".rst") or i.endswith(".md") or i.endswith(".txt") or os.isdir(os.path.join(SKETCH_UNITS,i))):
        shutil.copy(os.path.join(SKETCH_UNITS,i),  "/run/systemd/system")

for i in sorted(list(os.listdir(SKETCH_CONFIG)), reverse=True):
    if i.endswith(".ini") or i.endswith(".conf"):
        config.read(os.path.join(SKETCH_CONFIG,i))

#Start all the services listed in the config

#For now, let's not allow disabling anything at runtime
#That might cause issues if they were already enabled.
if 'units' in config:
    for i in config['units']:
        if config['units'][i].lower() in ("enable","true","yes","enabled"):
            try:
                for i in sorted(list(os.listdir(SKETCH_CONFIG))):
                    subprocess.call("systemctl","start",i)
            except:
                print(traceback.format_exc())
            