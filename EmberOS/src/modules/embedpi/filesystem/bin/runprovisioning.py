#!/usr/bin/python3

import subprocess,os,shutil,sys


if os.path.exists("/sketch/provisioning.sh"):
    print("Found provisioning file!")
    with open("/sketch/provisioning.sh.log", "wb") as f:
        try:
            output = subprocess.check_output(
                cmnd, stderr=subprocess.STDOUT, shell=True, timeout=3,
                universal_newlines=True)
        except subprocess.CalledProcessError as exc:
            print("Status : FAIL", exc.returncode, exc.output)
            f.write(exc.output)
            sys.exit()
        else:
            print(output)
            f.write(output)

    print("Success!")
    #Move it so it doesn't try to run again
    shutil.move("/sketch/provisioning.sh", "/sketch/provisioning.sh.RAN")