#!/bin/bash -eux

##
## VMware related stuff
## Install VMware related tools
##

echo '> Installing VMware Related/Virtualization packages...'

apt-get install -y \
  cloud-guest-utils \
  open-vm-tools

echo '> Done'