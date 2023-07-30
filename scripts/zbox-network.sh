#!/bin/bash -eux

##
## Debian Network
## Install Network utilities
##


echo '> Installing Network utilities...'

apt-get install -y \
  frr \
  ntp \
  curl \
  wget \
  rsync \
  ipcalc \
  telnet \
  dnsmasq \
  mtr-tiny \
  wireguard \
  traceroute \
  speedometer \
  bridge-utils \
  netcat-traditional

echo '> Done'
