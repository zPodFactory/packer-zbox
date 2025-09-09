#!/bin/bash -eux

##
## Debian Network
## Install Network utilities
##


echo '> Installing Network utilities...'

apt-get install -y \
  gping \
  rsync \
  ipcalc \
  telnet \
  dnsmasq \
  tcpdump \
  openntpd \
  mtr-tiny \
  wireguard \
  traceroute \
  speedometer \
  bridge-utils \
  netcat-traditional

# Install Doggo fancy DNS Client (json output possible, great with jq)
curl -sS https://raw.githubusercontent.com/mr-karan/doggo/main/install.sh | /bin/sh && chown root:root /usr/local/bin/doggo

#
# Install wakey (wake on lan cli tool)
# https://github.com/jonathanruiz/wakey
#
wget -qO /usr/local/bin/wakey https://github.com/jonathanruiz/wakey/releases/latest/download/wakey_linux_amd64 && chmod +x /usr/local/bin/wakey

echo '> Done'
