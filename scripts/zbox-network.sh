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

echo '> Done'
