## Project Name Here

This is an Ansible project folder based on the EmberOS template.  Note: the default template will only
back up *changed* files from the writable overlay.  With a few exceptions like /boot it will not capture any of the default EmberOS
data.




## Basic Info

### Purpose of this project

### Contact Info

### Physical device locations and info
Record where any servers are physically located and what is connected to them.

### Network setup info
Record any external servers the project communicates with, what network it is on, and how it connects to it

### Potential dangers

### Other relevant projects
Record any important external systems that are not reproducible with this repo.



## Major changes made

### Date

## Required periodic maintainence










## Using this ansible backup template

EmberOS formerly had it's own backup system.

Now everything is ansible-based, and we have a quickstart template to very easily back up and restore. 

For every project, copy the src/ansible template into your project folder, and rename it whatever you want.

Add your machines to the inventory.ini file under the \[emberos\] role.

Run the backup playbook and it will pull a backup from each machine, in roles/emberos/HOST/sketch and roles/emberos/HOST/boot.

You can have as many as you want, they stay separated by the actual hostname on the machine(Not the name given in the inventory file!).

To change what is included or excluded, see /roles/emberos/ignore.txt.

Use the deploy.yml to deploy everything.  


Note: By default, the backup includes network config from the device and other private data! *It is not meant to share publically!*

If you would like to share a backup as a ready-to-use appliance, you will probably need to modify the playbook to only copy whitelisted things,
or else you will need to hand edit(Be careful!).


I think that only using one role is appropriate here, since emberos isn't a cloud platform and you probably won't have many similar roles,
but this is just a template to semi-standardize things, edit as needed.
