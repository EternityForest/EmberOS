#!/usr/bin/python3

from __future__ import print_function
import sys, traceback


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


#Sorts by which ordrer we should do the bindings.
#Obviously we need to bind lower lever dirs before higher level ones.
#Or the lower ones would just cover everything up.
def bindSortKeyHelper(source, data):
    if isinstance(data, dict):
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

#Our current merged config
mergedConfig = {}

configdir = "/etc/fsbindings"


def tmpfs_overlay(onto, user, mode):
    "Apply a tmpfs overlay on top of whatever you pass it"
    tmp = "/dev/shm/" + onto.replace("/", "_") + "tmp"
    wrk = "/dev/shm/" + onto.replace("/", "_") + "work"
    subprocess.check_call(["mkdir", "-p", tmp])
    subprocess.check_call(["mkdir", "-p", wrk])
    subprocess.check_call(["chmod", mode, tmp])
    subprocess.check_call(["chmod", mode, wrk])
    subprocess.check_call(["chown", user, tmp])
    subprocess.check_call(["chown", user, wrk])
    subprocess.check_call([
        "mount", "-t", 'overlay', '-o',
        'lowerdir=' + onto + ',upperdir=' + tmp + ',workdir=' + wrk, 'overlay',
        onto
    ])


def overlay(upper, onto):
    "Apply a normal overlay on top of whatever you pass it"
    wrk = "/dev/shm/" + onto.replace("/", "_") + "work"
    subprocess.check_call(["mkdir", "-p", wrk])
    subprocess.check_call([
        "mount", "-t", 'overlay', '-o',
        'lowerdir=' + onto + ',upperdir=' + upper + ',workdir=' + wrk,
        'overlay', onto
    ])


for i in os.listdir(configdir):
    try:
        if i.endswith(".yaml"):
            with open(os.path.join(configdir, i)) as f:
                thisConfig = yaml.load(f.read())
                topLevelConfigToMerge = {}
                #Merge all the bindfile lists so we can define bindings for the same dir in multiple folders
                for j in thisConfig:
                    #Normalize
                    if not j.endswith("/"):
                        path = j + "/"
                    else:
                        path = j

                    #If it is not a string, that's because it's a simple binding
                    #Merge logic
                    if not isinstance(thisConfig[j], str):
                        if path in mergedConfig:
                            thisConfig[j]['referenced_by'] = mergedConfig[
                                path]['referenced_by']

                            b = mergedConfig[path].get("bindfiles", {})
                            newfiles = thisConfig[j].get("bindfiles", {})

                            for i in newfiles:
                                if i in b:
                                    raise RuntimeError(
                                        "Conflict on where to bind file:" + i)
                                else:
                                    b[i] = newfiles[i]

                            thisConfig[j]['bindfiles'] = b

                            for key in [
                                    'bindat', 'mode', 'user', 'pre_cmd',
                                    "post_cmd"
                            ]:
                                if key in mergedConfig[path]:
                                    if key in thisConfig[j]:
                                        raise RuntimeError(
                                            key +
                                            " was already specified for path "
                                            + j + " in another file")
                                    else:
                                        thisConfig[j][key] = mergedConfig[
                                            path][key]

                    topLevelConfigToMerge[path] = thisConfig[j]
                    if isinstance(topLevelConfigToMerge[path], dict):
                        if not "referenced_by" in topLevelConfigToMerge[path]:
                            topLevelConfigToMerge[path]['referenced_by'] = []

                        topLevelConfigToMerge[path]['referenced_by'].append(i)

                mergedConfig.update(topLevelConfigToMerge)
    except:
        eprint("Exception loading config file: " + i + "\n\n" +
               traceback.format_exc())

#Compute an effective bind point, which may just be the path itself if no bind is done
for i in sorted(list(mergedConfig.keys()),
                key=lambda x: bindSortKeyHelper(x, mergedConfig[x])):
    try:
        bindingConfig = mergedConfig[i]

        #Simple bindimng
        if isinstance(bindingConfig, str):
            continue

        if 'bindat' in bindingConfig:
            dest = bindingConfig['bindat']
        else:
            dest = i

        #Keep track of where we are actually going to mount it.
        bindingConfig['mounted_at'] = dest
    except:
        eprint("Exception \n\n" + traceback.format_exc())

print(yaml.dump(mergedConfig))

#Shortest first, to do upper dirs
#Use the length of whereever we are binding to,
for i in sorted(list(mergedConfig.keys()),
                key=lambda x: bindSortKeyHelper(x, mergedConfig[x])):
    try:
        bindingConfig = mergedConfig[i]

        if isinstance(bindingConfig, str):
            print("Simple Binding", bindingConfig)
            continue

        if 'bindat' in bindingConfig:
            dest = bindingConfig['bindat']
        else:
            dest = i

        if 'pre_cmd' in bindingConfig:
            print(bindingConfig['pre_cmd'])
            if isinstance(bindingConfig['pre_cmd'], str):
                subprocess.call(bindingConfig['pre_cmd'], shell=True)

            elif isinstance(bindingConfig['pre_cmd'], list):
                for command in bindingConfig['pre_cmd']:
                    subprocess.check_call(command, shell=True)

        if 'mode' in bindingConfig or 'user' in bindingConfig or 'bindat' in bindingConfig:
            if 'mode' in bindingConfig:
                m = str(bindingConfig['mode'])
                if len(m) == 3:
                    m = '0' + m

                for c in m:
                    if not c in "01234567":
                        raise RuntimeError(
                            "Nonsense mode" + m +
                            " ,mode should only contain 01234567. Try using quotes in the config?"
                        )
            else:
                m = None

            if not i.startswith("__"):
                if bindingConfig.get("type", "bindfs") == "bindfs":
                    cmd = ['bindfs', '-o', 'nonempty']
                    if m:
                        cmd.extend(['-p', m])
                    if 'user' in bindingConfig:
                        cmd.extend(['-u', bindingConfig['user']])
                    # Mount over itself with the given options
                    cmd.extend([i, dest])
                    print(cmd)
                    subprocess.call(cmd)
                elif bindingConfig.get("type", "bindfs") == "overlay":
                    overlay(i, dest)
                else:
                    raise RuntimeError("Bad binding type:" +
                                       bindingConfig.get("type", "bindfs"))

            else:
                if i.startswith("__tmpfsoverlay__"):
                    tmpfs_overlay(dest, bindingConfig['user'],
                                  bindingConfig['mode'])
                elif i == '__tmpfs__':
                    m = m or '1777'
                    subprocess.call([
                        "mount", "-t"
                        "tmpfs", "-o",
                        "size=" + str(bindingConfig.get('size', '32M')) +
                        ",mode=" + m + ",nonempty", "tmpfs", dest
                    ])

        if 'post_cmd' in bindingConfig:
            print(bindingConfig['post_cmd'])
            subprocess.call(bindingConfig['post_cmd'], shell=True)

    except:
        eprint("Exception in config for: " + i + "\n\n" +
               traceback.format_exc())


def searchConfig(f):
    if not f.endswith("/"):
        f = f + '/'

    if f in mergedConfig and not isinstance(mergedConfig[f], str):
        return f, mergedConfig[f]

    while len(f) > 1:
        #Split does not do what you think it should if path ends in /
        f = os.path.split(f if not f[-1] == '/' else f[:-1])[0]
        if not f.endswith("/"):
            f = f + '/'
        if f in mergedConfig and not isinstance(mergedConfig[f], str):
            return f, mergedConfig[f]
    return f, {}


#Now we handle simple bindings, and individual file bindings.
for i in sorted(list(mergedConfig.keys()),
                key=lambda x: bindSortKeyHelper(x, mergedConfig[x])):
    bindingConfig = mergedConfig[i]

    #Simple bindings
    if isinstance(bindingConfig, str):
        try:
            #Bind to the permission-transformed view, not the original
            #Not the search path thing, because we might be in a subfolder of something BindFSed elsewhere,
            #And we need to find that "elsewhere".

            #We don't have to worry about ordering relative to the permission transformed
            #views.sorted
            l, topConfig = searchConfig(i) or {}

            #Start with the path
            thisConfig = i

            mounted = topConfig.get('mounted_at', '/')

            if not mounted.endswith("/"):
                mounted = mounted + '/'

            #Now rebase it on wherever the topmost configured parent dir is mounted
            thisConfig = thisConfig.replace(l, mounted)

            cmd = [
                'mount', '--rbind', '-o', 'nonempty', thisConfig, bindingConfig
            ]
            print(cmd)
            subprocess.call(cmd)
        except:
            eprint("Exception in binding for: " + i + " on " + bindingConfig +
                   "\n\n" + traceback.format_exc())

    elif 'bindfiles' in bindingConfig:
        for j in bindingConfig['bindfiles']:
            dest = None
            try:
                dest = bindingConfig['bindfiles'][j]

                l, topConfig = searchConfig(i) or {}
                thisConfig = os.path.join(topConfig.get('mounted_at', '/'), i)

                mounted = topConfig.get('mounted_at', '/')

                if not mounted.endswith("/"):
                    mounted = mounted + '/'

                thisConfig = thisConfig.replace(l, mounted)
                thisConfig = os.path.join(thisConfig, j)
                cmd = ['mount', '--rbind', '-o', 'nonempty', thisConfig, dest]

                print(cmd)
                subprocess.call(cmd)
            except:
                eprint(
                    "Exception in binding for: " +
                    os.path.join(bindingConfig.get("mounted_at", "ERR"), j) +
                    " on " + dest + "\n\n" + traceback.format_exc())
