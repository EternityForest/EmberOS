#!/usr/bin/python3
# Copyright (C) 2022 daniel
# 
# This file is part of KaithemAutomation.
# 
# KaithemAutomation is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# KaithemAutomation is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with KaithemAutomation.  If not, see <http://www.gnu.org/licenses/>.



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
