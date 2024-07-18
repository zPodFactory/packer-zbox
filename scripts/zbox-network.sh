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
  tcpdump \
  mtr-tiny \
  wireguard \
  traceroute \
  speedometer \
  bridge-utils \
  netcat-traditional

# Disable FRR service
systemctl disable frr

# Install Doggo fancy DNS Client (json output possible, great with jq)
curl -sS https://raw.githubusercontent.com/mr-karan/doggo/main/install.sh | /bin/sh

echo '> Done'
