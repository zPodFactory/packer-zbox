#!/bin/bash -eux

##
## Debian system
## Install system utilities
##

echo '> Installing System Utilities...'

apt-get install -y \
  jq \
  bat \
  duf \
  eza \
  fzf \
  git \
  lsd \
  man \
  vim \
  btop \
  file \
  htop \
  lnav \
  make \
  ccze \
  tree \
  tmux \
  bzip2 \
  dstat \
  unzip \
  direnv \
  httpie \
  ripgrep \
  colordiff \
  colortail \
  syslog-ng \
  cloud-init

#
# Install fx (JSON tool)
# https://github.com/antonmedv/fx
#
curl https://fx.wtf/install.sh | sh

echo '> Done'
