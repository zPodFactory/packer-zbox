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

# Install wiper (disk usage TUI)
curl -L https://github.com/ikebastuz/wiper/releases/download/v0.2.1/wiper-x86_64-unknown-linux-gnu.tar.gz -o wiper.tar.gz
tar -xzf wiper.tar.gz
mv wiper /usr/local/bin
chmod +x /usr/local/bin/wiper
chown root:root /usr/local/bin/wiper
rm -vf wiper.tar.gz
rm -vf ._wiper

echo '> Done'