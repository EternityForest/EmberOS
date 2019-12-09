#!/usr/bin/python3


"""

Takes config files like


/sketch/config:
    bindat: /etc/sketchconfig

and 

/sketch/config:
    bindfiles:
        hosts: /etc/hosts
        hostname: /etc/hostname

and merges them together, then uses them to set up bindings.

In this case we are saying: Make /sketch/config viewable at /etc/sketchconfig.

Then, in another file, we say(Note relative paths), make /etc/sketchconfig/hosts viewable at /etc/hosts

All binding files lists for a path are merged together, you can specify multiple lists for one dir, in different config files.

If bindat is specified in more than one gile for a given path, it is undefined who wins.

Bindfiles relative paths are interpreted relative to bindat.

It is an error to use an absolute path for a bindfile source.

File bindings happen after the top level path bindings

"""

import yaml, subprocess, os

config = {}

configdir = "/sketch/config/filesystem/"
configdir = "/home/daniel/sandbox/config"

for i in os.listdir(configdir):
    if i.endswith(".yaml"):
        with open(os.path.join(configdir,i)) as f:
            x = yaml.load(f.read())
            #Merge all the bindfile lists so we can define bindings for the same dir in multiple folders
            for j in x:
                if j in config:
                    b = config[j].get("bindfiles",{})
                    b.update(x[j].get("bindfiles",{}))
                    x[j]['bindfiles'] = b
            config.update(x)

#Shortest first, to do upper dirs
for i in sorted(list(config.keys()),key=lambda x:len(x)):
    d = config[i]

        
    if 'bindat' in d:
        dest = d['bindat']
    else:
        dest=i

    #Keep track of where we mounted it    
    d['mounted_at'] = dest

    if 'mode' in d or 'user' in d or 'bindat' in d:
        cmd = ['bindfs','-o','nonempty']
        if 'mode' in d:
            m = str(d['mode'])
            if len(m)==3:
                m = '0'+m
            cmd.extend(['-p',m])
        if 'user' in d:
                cmd.extend(['-u', d['user']])
        #Mount over itself with the given options
        cmd.extend([i,dest])
        print(cmd)
        subprocess.call(cmd)


#Now we do the actual bind mounts that make them available in various places.
#This relies on the fact that you 
for i in sorted(list(config.keys()),key=lambda x:len(x)):
    d = config[i]
    
    if 'bindfiles' in d:
         for j in d['bindfiles']:
            dest =  d['bindfiles'][j]
            #Bind to the permission-transformed view, not the original
            cmd = ['mount', '--bind', '-o','nonempty', os.path.join(d['mounted_at'],j), dest]
            print(cmd)
            subprocess.call(cmd)