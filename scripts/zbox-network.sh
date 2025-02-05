#!/bin/bash -eux

##
## Debian Network
## Install Network utilities
##


echo '> Installing Network utilities...'

apt-get install -y \
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

# Install Doggo fancy DNS Client (json output possible, great with jq)
curl -sS https://raw.githubusercontent.com/mr-karan/doggo/main/install.sh | /bin/sh && chown root:root /usr/local/bin/doggo

echo '> Done'
