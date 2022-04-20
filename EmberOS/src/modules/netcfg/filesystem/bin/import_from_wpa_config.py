#!/usr/bin/python3

import subprocess
import re
import os
import configparser
import uuid

# Note: Will Not Work with PiWiz!!! They do some dhcpcd stuff.


n_re = r'network\s*=\s*{([\w\s=\"-]*?)}'

country_re = 'country\s*=\s*"?(...?)"?[\s$]'

# s = """
# country=US
# ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
# ap_scan=1

# update_config=1
# network={
# 	ssid="mynetwork"
# 	psk=69e49214ef4e7e23d0ece077c2faf3c73f7522ad52a26b33527fa78d9033ff35
# }
# """


if os.path.exists("/etc/wpa_supplicant/wpa_supplicant.conf"):
    with open("/etc/wpa_supplicant/wpa_supplicant.conf",'r') as f:
        s=f.read()


template = """
# This file has been imported from a wpa_supplicant configuration
# DO NOT MANUALLY CHANGE THIS FILE. CHANGES WILL BE OVERWRITTEN.
# IF YOU COPY THE FILE CONTENTS, GET RID OF THIS MARKER LINE OR
# iT WILL BE DELETED BY THE IMPORTER.
# imported_marker = b2bdb0b4-11da-40f2-b121-e50a1fe6a7d9

[connection]
#You can change that name
id=YourWifiNameHere
uuid=f671d4c3-2ae0-417d-ad5a-9bc1d040b0ec
type=wifi
#Fake timestamp to make it think it has connected before,
#And attemp to avoid the "only one attempt then give up" problem
timestamp=123456
permissions=


[wifi]
mac-address-blacklist=
mode=infrastructure

ssid=YourWifiNameHere

#Just straight up delete this whole section
#To connect to unsecured networks
[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=YourWifiPasswordHere

[ipv4]
dns-search=
method=auto

#You can do DHCP but also add manual static addresses
#addresses=192.168.0.200/24

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto
"""
nsuid = "9cf4c103-f2bf-4ff3-a122-91cda420186b"


valid_uuids = {}


# Set the regulatory domain
for i in re.findall(country_re,s):
    subprocess.call(['iw','reg','set', i])


try:
    os.makedirs("/etc/NetworkManager/system-connections/",mode=16877)
except Exception:
    pass

for i in re.findall(n_re,s):
    c = configparser.ConfigParser()
    c.read_string("[d]\r\n"+i)
    c = c['d']
    if 'ssid' in c and 'psk' in c:
        t2 = template.replace('YourWifiNameHere',c['ssid'].replace('"','') if c['ssid'].startswith('"') else c['ssid'])
        t2 = t2.replace('YourWifiPasswordHere',c['psk'])
        u = uuid.uuid5(uuid.UUID(nsuid),c['ssid']+ "/" + c['psk'] )
        valid_uuids[str(u)] = True
        t2 = t2.replace('f671d4c3-2ae0-417d-ad5a-9bc1d040b0ec', str(u))

        path = "/etc/NetworkManager/system-connections/"+"wpaconf_donotedit"+c['ssid'].replace("/",'_').replace('"','').replace(" ",'_')


        if os.path.exists(path):
            with open(path) as f:
                if t2==f.read():
                    continue

        with open(path,'w') as f:
            f.write(t2)

        if not os.stat(path).st_mode == '0o100600':
            os.chmod(path, 0o100600)

for i in list(os.listdir("/etc/NetworkManager/system-connections/")):
    d = os.path.join("/etc/NetworkManager/system-connections/", i)

    with open(d,'r') as f:
        s = f.read()
    
    if "b2bdb0b4-11da-40f2-b121-e50a1fe6a7d9" in s:
        # Now we know it was made be this app

        valid = 0
        for j in valid_uuids:
            if j in s:
                # We found one of the UUIDs that we know comes from one of our files
                valid = 1
        if not valid:
             os.remove(d)
        
		
