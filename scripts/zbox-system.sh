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
# Install eza (a modern replacement for ls)
# https://github.com/eza-community/eza
#
curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz
chmod +x eza
chown root:root eza
mv eza /usr/local/bin/eza


#
# Install fx (JSON tool)
# https://github.com/antonmedv/fx
#
curl https://fx.wtf/install.sh | sh

echo '> Done'
