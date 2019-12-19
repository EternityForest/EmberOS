#!/usr/bin/python3

from __future__ import print_function
import sys,traceback

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

"""

Takes config files like


/sketch/config:
    bindat: /etc/sketchconfig

and 

/sketch/config:
    bindfiles:
        hosts: /etc/hosts
        hostname: /etc/hostname

/sketch/config/simple: /simple

and merges them together, then uses them to set up bindings.

In this case we are saying: Make /sketch/config viewable at /etc/sketchconfig.

in the second file, we say(Note relative paths), make /etc/sketchconfig/hosts viewable at /etc/hosts

Bindfiles are relative to the main bindat location for that path.

The line /sketch/config/simple: /simple binds  /etc/sketchconfig/simple to /simple,
because the path gets rebased on the top configured directory/

All binding files lists for a path are merged together, you can specify multiple lists for one dir, in different config files.

If bindat is specified in more than one gile for a given path, it is undefined who wins.

Bindfiles relative paths are interpreted relative to bindat.

It is an error to use an absolute path for a bindfile source.

File bindings happen after the top level path bindings

"""

import yaml, subprocess, os

config = {}

configdir = "/sketch/config/filesystem/"
#configdir = "/home/daniel/sandbox/config/"

for i in os.listdir(configdir):
    try:
        if i.endswith(".yaml"):
            with open(os.path.join(configdir,i)) as f:
                x = yaml.load(f.read())
                x2 ={}
                #Merge all the bindfile lists so we can define bindings for the same dir in multiple folders
                for j in x:
                    #Normalize
                    if not j.endswith("/"):
                        path=j+"/"
                    else:
                        path = j

                    if not isinstance(x[j],str):
                        if path in config:
                            b = config[path].get("bindfiles",{})
                            b.update(x[j].get("bindfiles",{}))
                            x[j]['bindfiles'] = b

                            for key in ['bindat','mode','user']:
                                if key in config[path] and key in x[j]:
                                    raise RuntimeError(key+" was already specified for path "+j +" in another file")

                    x2[path]=x[j]

                config.update(x2)
    except:
        eprint("Exception loading config file: "+i+"\n\n"+traceback.format_exc())





#Compute an effective bind point, which may just be the path itself if no bind is done
for i in sorted(list(config.keys()),key=lambda x:len(x)):
    try:
        d = config[i]
        if isinstance(d,str):
            continue
            
        if 'bindat' in d:
            dest = d['bindat']
        else:
            dest=i

        #Keep track of where we mounted it    
        d['mounted_at'] = dest
    except:
        eprint("Exception \n\n"+traceback.format_exc())



print(yaml.dump(config))


#Shortest first, to do upper dirs
for i in sorted(list(config.keys()),key=lambda x:len(x)):
    try:
        d = config[i]
        if isinstance(d,str):
            print("Simple Binding",d)
            continue

        if 'bindat' in d:
            dest = d['bindat']
        else:
            dest=i

        if 'pre_cmd' in d:
            print(d['pre_cmd'])
            subprocess.call(d['pre_cmd'],shell=True)


        if 'mode' in d or 'user' in d or 'bindat' in d:
            cmd = ['bindfs','-o','nonempty']
            if 'mode' in d:
                m = str(d['mode'])
                if len(m)==3:
                    m = '0'+m

                for c in m:
                    if not c in "01234567":
                        raise RuntimeError("Nonsense mode"+m+" ,mode should only contain 01234567. Try using quotes in the config?")
                cmd.extend(['-p',m])
            if 'user' in d:
                    cmd.extend(['-u', d['user']])
            #Mount over itself with the given options
            cmd.extend([i,dest])
            print(cmd)
            subprocess.call(cmd)
        
        if 'post_cmd' in d:
            print(d['post_cmd'])
            subprocess.call(d['post_cmd'],shell=True)

    except:
        eprint("Exception in config for: "+i+"\n\n"+traceback.format_exc())



def searchConfig(f):
    if not f.endswith("/"):
        f = f+'/'

    if f in config and not isinstance(config[f],str):
        return f, config[f]
    
    while len(f)>1:
        #Split does not do what you think it should if path ends in /
        f = os.path.split(f if not f[-1]=='/' else f[:-1])[0]
        if not f.endswith("/"):
            f = f+'/'
        if f in config and not isinstance(config[f],str):
            return f,config[f]
    return f,{}

#Now we do the actual bind mounts that make them available in various places.
#This relies on the fact that you 
for i in sorted(list(config.keys()),key=lambda x:len(x)):
   
    d = config[i]
    
    #Simple bindings
    if isinstance(d,str):
        try:
            #Bind to the permission-transformed view, not the original
            #Not the search path thing, because we might be in a subfolder of something BindFSed elsewhere,
            #And we need to find that "elsewhere"
            l,topConfig = searchConfig(i) or {}

            #Start with the path
            x = i

            mounted =  topConfig.get('mounted_at','/')

            if not mounted.endswith("/"):
                mounted = mounted+'/'

            #Now rebase it on wherever the topmost configured parent dir is mounted
            x = x.replace(l,mounted)

            cmd = ['mount', '--rbind', '-o','nonempty',x, d]
            print(cmd)
            subprocess.call(cmd)
        except:
            eprint("Exception in binding for: "+i+" on "+d+"\n\n"+traceback.format_exc())

    elif 'bindfiles' in d:
         for j in d['bindfiles']:
            try:
                dest =  d['bindfiles'][j]
                
                l,topConfig = searchConfig(i) or {}
                x = os.path.join(topConfig.get('mounted_at','/'),i)

                mounted =  topConfig.get('mounted_at','/')

                if not mounted.endswith("/"):
                    mounted = mounted+'/'

                x = x.replace(l,mounted)
                x=os.path.join(x,j)
                cmd = ['mount', '--rbind', '-o','nonempty',x, dest]
                
                print(cmd)
                subprocess.call(cmd)
            except:
                eprint("Exception in binding for: "+os.path.join(d.get("mounted_at","ERR"),j)+" on "+dest+"\n\n"+traceback.format_exc())

