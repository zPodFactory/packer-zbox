#!/bin/bash -eux

##
## Debian Network
## Install Network utilities
##


echo '> Installing Network utilities...'

apt-get install -y \
  gping \
  rsync \
  chrony \
  ipcalc \
  telnet \
  dnsmasq \
  dnsutils \
  tcpdump \
  mtr-tiny \
  wireguard \
  traceroute \
  speedometer \
  bridge-utils \
  netcat-traditional


# Install Doggo fancy DNS Client (json output possible, great with jq)
curl -sS https://raw.githubusercontent.com/mr-karan/doggo/main/install.sh | /bin/sh && chown root:root /usr/local/bin/doggo

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
# Install xfr (A modern iperf3 alternative with a live TUI, multi-client server, and QUIC support)
# https://github.com/lance0/xfr
#
curl -fsSL https://github.com/lance0/xfr/releases/latest/download/xfr-x86_64-unknown-linux-musl.tar.gz \
 | tar -xz -C /usr/local/bin xfr \
 && chown root:root /usr/local/bin/xfr

#
# Install surge (fast download manager)
# https://github.com/surge-downloader/surge
#
curl -fsSL -o /dev/null -w "%{url_effective}" -L https://github.com/surge-downloader/Surge/releases/latest \
| sed 's#.*/tag/v##' \
| xargs -I T sh -c 'curl -fsSL https://github.com/surge-downloader/Surge/releases/download/vT/Surge_T_linux_amd64.tar.gz \
  | tar -xzO surge > /usr/local/bin/surge' \
&& chmod 0755 /usr/local/bin/surge

echo '> Done'
