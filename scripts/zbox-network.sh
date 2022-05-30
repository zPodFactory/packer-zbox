#!/bin/bash -eux

##
## Debian Network
## Install Network utilities
##


echo '> Installing Network utilities...'

apt-get install -y \
  ntp \
  frr \
  curl \
  wget \
  rsync \
  ipcalc \
  telnet \
  netcat \
  dnsmasq \
  mtr-tiny \
  wireguard \
  speedometer \
  bridge-utils

# Fancy dig like for dns with JSON support: https://dns.lookup.dog/
# Compiled by me into a near portable executable ... (trust or not :D)

#wget -q https://cloud.tsugliani.fr/zbox/dog -O /usr/local/bin/dog
#chmod +x /usr/local/bin/dog

echo '> Done'
