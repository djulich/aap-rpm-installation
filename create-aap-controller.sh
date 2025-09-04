sudo virt-install \
  --name aap-controller \
  --description 'AAP Controller on RHEL 9.6' \
  --ram 8192 \
  --vcpus 2 \
  --disk /var/lib/libvirt/images/aap-controller.qcow2,size=50,bus=virtio \
  --os-variant rhel9.5 \
  --network bridge=br0,model=virtio \
  --graphics none \
  --location /var/lib/libvirt/images/rhel-9.6-x86_64-dvd.iso \
  --initrd-inject=/var/lib/libvirt/images/aap_ks.cfg \
  --extra-args="inst.ks=file:/aap_ks.cfg console=ttyS0 inst.text inst.hostname=aap-controller"

