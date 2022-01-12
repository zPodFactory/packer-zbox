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
  ccze \
  tree \
  tmux \
  htop \
  dstat \
  unzip \
  httpie

# nice df https://github.com/muesli/duf
curl -L https://github.com/muesli/duf/releases/download/v0.7.0/duf_0.7.0_linux_amd64.deb -o /tmp/duf.deb
dpkg -i /tmp/duf.deb 
rm -vf /tmp/duf.deb

echo '> Done'