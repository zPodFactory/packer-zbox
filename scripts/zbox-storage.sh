#!/bin/bash -eux

##
## Debian Storage
## Install Storage utilities
##

echo '> Installing Storage utilities...'

apt-get install -y \
  gdu \
  lftp \
  pure-ftpd \
  nfs-kernel-server

echo '> Done'