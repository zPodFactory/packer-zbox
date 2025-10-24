#!/bin/bash -eux

##
## VMware related stuff
## Install VMware related tools
##

echo '> Installing VMware Related/Virtualization packages...'

apt-get install -y \
  cloud-guest-utils \
  open-vm-tools

# Disable VMware guest tools customization of the VM
# OVF Properties / cloud-init configuration can be used.
cat >> /etc/vmware-tools/tools.conf << 'EOF'
[deployPkg]
enable-customization=false
EOF


echo '> Done'