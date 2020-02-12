#!/usr/bin/python3

from __future__ import print_function
import sys,traceback

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def bindSortKeyHelper(source,data):
    if isinstance(data,dict):
        if 'bindat' in data:
            return len(data['bindat'])
        else:
            #Default to on top of the source
            return len(source)
    else:
        #Simple binding
        return len(source)
    

"""

Takes config files like

----------------------------------------

# Complex binding, implemented with more advanced tools like bindfs
# Any binding that isn't just a target string is considered complex.
/sketch/config:
    # If not present, the dir binds on top of itself.
    bindat: /etc/sketchconfig

and 

/sketch/config:
    bindat: /etc/sketchconfig

    # You can think of a mode as applying that permission
    # to the folder itself, even thoug the transformed view is elsewhere.

    #Simple bindings sources from /sketch/config are automatically
    #Mapped to the transformed view.
    mode: "0755"

    #Note: This actually binds /etc/sketchconfig/hosts
    #Not /sketch/config/hosts
    #Because bindfiles uses the permission-transformed view
    bindfiles:
        hosts: /etc/hosts
        hostname: /etc/hostname

    pre_cmd:
        - SomeCommand
        - SomeOtherCommanda
and:

#This will actually bind /etc/sketchconfig/simple, because
#Simple bindings use permission transformed views.

#It does not matter if the simple binding is in the same file
#As the complex binding it is based on

#A simple binding is defined just by a string target
/sketch/config/simple: /simple


#This one binds a tmpfs on top of /foo/bar.
#It will be ordered correctly with everything else based on bindat.
#Tmpfses are complex bindings.
# All three params are mandatory 
#Name must be unique. For real.

__tmpfsoverlay__UNIQUENAME:
    bindat: /foo/bar
    mode: 0755
    user: pi 
-----------------


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

File bindings happen after the top level path bindings.


Pre_cmd is executed before the binding happends, post_cmd comes after.

pre_cmd can be a single command line, or a list of them.


Bindings happen in two steps. First the complex bindings,
then the file bindings and the simple bindings.

In each step, whatever has the shortest target path is always bound first(To do otherwise
would interfere with layering, and higher level subdirs woud cover things up.).


You should not use a subfolder of any binding as the source for a complex binding,
as the ordering is defined based on the destinations.

"""

import yaml, subprocess, os

config = {}

configdir = "/sketch/config/filesystem/"
#configdir = "/home/daniel/sandbox/config/"



def tmpfs_overlay(onto, user, mode):
    "Apply a tmpfs overlay on top of whatever you pass it"
    tmp = "/dev/shm/"+onto.replace("/","_")+"tmp"
    wrk = "/dev/shm/"+onto.replace("/","_")+"work"
    subprocess.check_call(["mkdir", "-p",tmp])
    subprocess.check_call(["mkdir", "-p",wrk])
    subprocess.check_call(["chmod", mode, tmp])
    subprocess.check_call(["chmod", mode, wrk])
    subprocess.check_call(["chown", mode, tmp])
    subprocess.check_call(["chown", mode, wrk])
    subprocess.check_call(["mount", "-t", 'overlay', '-o','lowerdir='+onto+',upperdir='+tmp+',workdir='+wrk,'overlay',onto])
    


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
                            x[j]['referenced_by'] = config[path]['referenced_by']

                            b = config[path].get("bindfiles",{})
                            newfiles = x[j].get("bindfiles",{})

                            for i in newfiles:
                                if i in b:
                                    raise RuntimeError("Conflict on where to bind file:"+i)
                                else:
                                    b[i]=newfiles[i]

                            x[j]['bindfiles'] = b


                            for key in ['bindat','mode','user']:
                                if key in config[path]:
                                    if key in x[j]:
                                        raise RuntimeError(key+" was already specified for path "+j +" in another file")
                                    else:
                                       x[j][key] = config[path][key]


                    x2[path]=x[j]
                    if isinstance(x2[path],dict):
                        if not "referenced_by" in x2[path]:
                            x2[path]['referenced_by']=[]
                        
                        x2[path]['referenced_by'].append(i)

                config.update(x2)
    except:
        eprint("Exception loading config file: "+i+"\n\n"+traceback.format_exc())





#Compute an effective bind point, which may just be the path itself if no bind is done
for i in sorted(list(config.keys()),key=lambda x:bindSortKeyHelper(x,config[x])):
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
#Use the length of whereever we are binding to, 
for i in sorted(list(config.keys()),key=lambda x:bindSortKeyHelper(x,config[x])):
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
            if isinstance(d['pre_cmd'], str):
                subprocess.call(d['pre_cmd'],shell=True)

            elif isinstance(d['pre_cmd'], list):
                for command in d['pre_cmd']:
                    subprocess.check_call(command,shell=True)


        if 'mode' in d or 'user' in d or 'bindat' in d:
            if 'mode' in d:
                m = str(d['mode'])
                if len(m)==3:
                    m = '0'+m

                for c in m:
                    if not c in "01234567":
                        raise RuntimeError("Nonsense mode"+m+" ,mode should only contain 01234567. Try using quotes in the config?")
            else:
                m=None

            if not i.startswith("__"):
                
                cmd = ['bindfs', '-o','-nonempty']
                if m:
                    cmd.extend(['-p',m])
                if 'user' in d:
                        cmd.extend(['-u', d['user']])
                #Mount over itself with the given options
                cmd.extend([i,dest])
                print(cmd)
                subprocess.call(cmd)
            
            else:
                if i.startswith("__tmpfsoverlay__"):
                    tmpfs_overlay(dest, d['user'],d['mode'])
        
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

#Now we handle simple bindings, and individual file bindings.
for i in sorted(list(config.keys()),key=lambda x:bindSortKeyHelper(x,config[x])):   
    d = config[i]
    
    #Simple bindings
    if isinstance(d,str):
        try:
            #Bind to the permission-transformed view, not the original
            #Not the search path thing, because we might be in a subfolder of something BindFSed elsewhere,
            #And we need to find that "elsewhere".

            #We don't have to worry about ordering relative to the permission transformed
            #views.sorted
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

