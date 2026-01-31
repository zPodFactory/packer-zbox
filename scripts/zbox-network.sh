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

#
# Install snitch (a prettier way to inspect network connections)
# https://github.com/karol-broda/snitch
#
curl -sSL https://raw.githubusercontent.com/karol-broda/snitch/master/install.sh | sh

#
# Install witr (Why is this running? )
# https://github.com/pranshuparmar/witr
#
curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash


#
# Install ttl (Fast, modern traceroute with real-time TUI)
# https://github.com/lance0/ttl
#
sh -c "$(curl -fsSL https://raw.githubusercontent.com/lance0/ttl/master/install.sh)" <<<'Y' \
&& chown root:root /usr/local/bin/ttl

#
# Install surge (fast download manager)
# https://github.com/surge-downloader/surge
#
curl -fsSL https://github.com/surge-downloader/surge/releases/download/v0.4/surge_0.4_linux_amd64.tar.gz \
 | tar -xz -C /usr/local/bin surge \
 && chown root:root /usr/local/bin/surge

echo '> Done'
