# aap-rpm-installation

This repository contains information and resource files to support AAP installation via RPM onto nodes running in local VMs, mainly for debugging customer issues.

## Steps to install AAP 2.4 or 2.5 on your laptop

1. Download RHEL image from here: https://access.redhat.com/downloads/content/rhel
2. Copy RHEL image to the libvirt image folder, e.g. `/var/lib/libvirt/images/rhel-9.6-x86_64-dvd.iso`
3. Get or create RHEL subscription activation key here: https://console.redhat.com/insights/connector/activation-keys
4. Get or create an SSH public key for the host: `$ ssh-keygen -t ed25519` `$ cat .ssh/id_ed25519.pub | xsel -ib`
5. Adjust `aap_ks.cfg` with the activation key from step 3. and with the ssh public key from step 4.
5. Copy `aap_ks.cfg` to libvirt image folder: `/var/lib/libvirt/images/aap_ks.cfg`
6. If using another RHEL image than 9.6, adjust the image name in the `create-aap-???.sh` scripts.
7. Execute `create-aap-controller.sh`
8. Execute `create-aap-gateway.sh`
9. Execute `create-aap-db.sh`
10. Get the IPv4 addresses of the VMs (`sudo virsh domifaddr <vmname>` or `sudo virsh console <vmname>`, login ansible/ansible, `ip a`)
11. Get the AAP installer (Setup Bundle) from here: https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.4/x86_64/product-software
12. Extract the setup-bundle into this folder, e.g. `tar -xvzf ~/Downloads/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64.tar.gz -C ~/repos/aap-rpm-installation/`
13. Adjust `inventory-for-setup-x.x` with IP addresses from step 10.
14. Execute `setup.sh` from the setup-bundle `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.4`

## Steps for restoring a backup

1. Install the AAP version which created the backup file (see installation instructions above).
2. Copy the backup file (e.g. `automation-platform-backup-latest.tar.gz`) into the extracted setup-bundle of the installer from step 1.
3. Make sure the `inventory-for-setup-x.x` contains the correct IPv4 addresses.
4. Execute `setup.sh` in the setup-bundle from step 1 with option -r, e.g. `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.4-6.2-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.4 -r`

Notes:
- If the backup file is in another location (than the setup-bundle root), add `-e "restore_backup_file=<path-to-backup-file>"` to the `setup.sh` command line.

## Steps for updating AAP

1. Get the AAP installer (Setup Bundle) for the target version from here: https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.5/x86_64/product-software
2. Extract the setup-bundle into this folder, e.g. `tar -xvzf ~/Downloads/ansible-automation-platform-setup-bundle-2.5-17-x86_64 -C ~/repos/aap-rpm-installation/`
3. Make sure the `inventory-for-setup-x.x` contains the correct IPv4 addresses.
4. Execute `setup.sh` in the setup-bundle from step 1 and pass the correct inventory for the target version, e.g. `~/repos/aap-rpm-installation/ansible-automation-platform-setup-bundle-2.5-17-x86_64/setup.sh -i ~/repos/aap-rpm-installation/inventory-for-setup-2.5`

Notes:
- If the update process stops unexpectedly when setup wants to download some packages (e.g. cryptography) from the RHEl registry, it may be because the time on one of the node VMs is not synced. To fix the VM time, issue inside the VM: `sudo systemctl restart chronyd && sudo chronyc -a makestep` or, on the host: `sudo virsh domtime <VM-NAME> --sync`.

## Additional Information

### General Notes

- The following step-by-step instructions assume that the working directory is this repo, e.g. `~/repos/aap-rpm-installation`.
- The aap installer can be run on the host or on the controller node VM. This description focuses on running setup.sh from the host.
- If running setup.sh on the host complains about the wrong ansible-core version (e.g. "Unable to install the required version of ansible-core (2.16)"), you should run setup.sh from a Python venv: 
    ```
    $ python3 -m venv ~/aap-venv
    $ source ~/aap-venv/bin/activate
    $ pip install --upgrade pip
    $ pip install "setuptools<69"
    $ pip install "ansible-core>=2.16,<2.17"
    $ pip install packaging wheel
    ```

### Working with VMs

#### Using virsh

Maybe you have noticed that you can see your VMs only with either `virsh list --all` or `sudo virsh list --all`. This is because `virsh` connects to different `libvirt` instances in these two cases. To enforce always the same libvirt instance, add the following line to `~/.config/libvirt/libvirt.conf`:
```
uri_default = "qemu:///system"
```

Alternatively, you can also use an evironment variable to achieve the same:
```
export LIBVIRT_DEFAULT_URI=qemu:///system
```

Verify which URI `virsh` uses by
```
virsh uri
```

#### Connecting to a VM console

```
sudo virsh console aap-controller
```
You can only exit from this console with the escape character which is printed after the console has been created. Usually it is `^]` (`<ctrl>` + `]`).

This is typically only needed if you don't have ssh setup for this VM already, or to retrieve the VMs IP address with `ip a` (if the network in the VM is configured to DHCP and a `sudo virsh domifaddr <VM>` from the host doesn't return the VMs IP address, which sometimes happens). Otherwise just ssh into the VM.

#### VM Snapshots

When working with VMs it is good practice create snapshots at critical steps, e.g. before a backup is restored, or before an update is attempted.

For details visit the [official documentation](https://www.libvirt.org/manpages/virsh.html#snapshot-commands).

##### Creating a snapshot

```
sudo virsh snapshot-create-as --domain aap-controller --name 1-fresh-install --atomic
```

If you use `--disk-only` to save disk space, you have to shutdown the VM first, e.g. by `sudo virsh destroy aap-controller`.

##### Reverting to a snapshot

List the available snaphots for a VM:
```
sudo virsh snapshot-list aap-controller
```

Revert a VM to a snapshot:
```
sudo virsh snapshot-revert aap-controller 1-fresh-install
```

#### VM Time

After a VM is started or reverted to a snapshot, the time inside the VM is usually way off. This can cause all kinds of problems, e.g. that a RHEL subscription is invalid because the activation key is not yet valid at the VM time.

##### Sync time from the Host

If the `qemu-guest-agent` is running on the VM, you can sync the VM time with the following command issued on the host:
```
sudo virsh domtime <VM-NAME> --sync
```

You can also make libvirt issue this command whenever a VM is started, by adding the following line to `/etc/libvirt/hooks/qemu`:
```
virsh domtime "$1" --sync
```

##### Sync time from inside the VM

From inside the VM, you can sync the time with the following commands:
```
sudo systemctl restart chronyd
sudo chronyc -a makestep
```

Note that it still takes a few seconds after these commands are issued until the VM time is actually synced.
