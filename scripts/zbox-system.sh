#!/bin/bash -eux

##
## Debian system
## Install system utilities
##

echo '> Installing System Utilities...'

apt-get install -y \
  jq \
  bat \
  exa \
  fzf \
  git \
  man \
  vim \
  make \
  ccze \
  tree \
  tmux \
  htop \
  bzip2 \
  dstat \
  unzip \
  httpie

echo '> Installing duf...'
# nice df alternative (duf): https://github.com/muesli/duf
wget -q https://github.com/muesli/duf/releases/download/v0.7.0/duf_0.7.0_linux_amd64.deb -O /tmp/duf.deb
dpkg -i /tmp/duf.deb 
rm -vf /tmp/duf.deb

echo '> Installing btop...'
# nice top alternative (btop): https://github.com/aristocratos/btop
mkdir /tmp/btop 
wget -q https://github.com/aristocratos/btop/releases/download/v1.2.0/btop-x86_64-linux-musl.tbz -O /tmp/btop/btop.tbz
cd /tmp/btop
tar -xvjf btop.tbz
./install.sh
cd -
rm -rf /tmp/btop

echo '> Done'