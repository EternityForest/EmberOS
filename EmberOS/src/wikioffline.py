#!/usr/bin/python3
from zimply import ZIMServer
import os, sys,subprocess,threading,time
wikisdir = '/home/daniel/Wikis/'
indexdir = '/home/daniel/Wikis/'

x = None

indexdir=os.path.expanduser(indexdir)

subprocess.check_call(["mkdir","-p",indexdir])
print("Looking for files in:"+wikisdir+sys.argv[1])
for i in os.listdir(wikisdir+sys.argv[1]):
    if i.endswith(".zim"):
        x = os.path.join(wikisdir+sys.argv[1], i)
        print("Serving: "+x)
        break

print("Using port: "+sys.argv[2])
def f():
    ZIMServer(x, port=int(sys.argv[2]),index_file=os.path.join(indexdir,os.path.basename(x)+".index"))
threading.Thread(target=f).start()

import requests
print("Launching browser(You may need to refresh in a few minutes if the index isn't there")
time.sleep(1)
subprocess.check_call(["chromium-browser","--incognito", "http://localhost:"+sys.argv[2]])
