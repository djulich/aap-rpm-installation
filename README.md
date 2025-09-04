# aap-rpm-installation

## Steps to install AAP 2.4 or 2.5 on your laptop

1. Download RHEL image from here: https://access.redhat.com/downloads/content/rhel
2. Copy RHEL image to libvirt image folder, e.g. `/var/lib/libvirt/images/rhel-9.6-x86_64-dvd.iso`
3. Get or create RHEL subscription activation key here: https://console.redhat.com/insights/connector/activation-keys
4. Get or create an SSH public key for the host: `$ ssh-keygen -t ed25519` `$ cat .ssh/id_ed25519.pub | xsel -ib`
5. Adjust aap_ks.cfg with the activation key from setop 3. and with the ssh public key from step 4.
5. Copy `aap_ks.cfg` to libvirt image folder: `/var/lib/libvirt/images/aap_ks.cfg`
6. If using another RHEL image than 9.6, adjust the image name in the create-aap-???.sh scripts.
7. Execute `create-aap-controller.sh`
8. Execute `create-aap-gateway.sh`
9. Execute `create-aap-db.sh`
10. Get the IPv4 addresses of the VMs (`sudo virsh domifaddr <vmname>` or `sudo virsh console <vmname>`, login ansible/ansible, `ip a`)
11. Get the AAP installer (Setup Bundle) from here: https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.4/x86_64/product-software
12. Extract the setup-bundle into this folder, e.g. `tar -xvzf ~/Downloads/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64.tar.gz -C ~/repos/aap-rpm-installation/`
13. Adjust inventory-for-setup-x.x with IP addresses from step 10.
14. Execute setup.sh from the setup-bundle `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.4`

## Steps for restoring a backup

1. Install the AAP version which created the backup file (see installation instructions above).
2. Copy the backup file (e.g. `automation-platform-backup-latest.tar.gz`) into the extracted setup-bundle of the installer from step 1.
3. Make sure the `inventory-for-setup-x.x` contains the correct IPv4 addresses.
4. Execute setup.sh in the setup-bundle from step 1 with option -r, e.g. `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.4 -r`

Notes:
- If the backup file is in another location (than the setup-bundle root), add `-e "restore_backup_file=<path-to-backup-file>"` to the setup.sh command line.

## Steps for updating AAP

1. Get the AAP installer (Setup Bundle) for the target version from here: https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.5/x86_64/product-software
2. Extract the setup-bundle into this folder, e.g. `tar -xvzf ~/Downloads/ansible-automation-platform-setup-bundle-2.5-17-x86_64 -C ~/repos/aap-rpm-installation/`
3. Make sure the `inventory-for-setup-x.x` contains the correct IPv4 addresses.
4. Execute setup.sh in the setup-bundle from step 1 and pass the correct inventory for the target version, e.g. `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.5-17-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.5`

