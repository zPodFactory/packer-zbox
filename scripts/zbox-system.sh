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


#
# Install chezmoi (https://chezmoi.io/)
# https://github.com/twpayne/chezmoi
#
curl -s https://api.github.com/repos/twpayne/chezmoi/releases/latest \
| grep browser_download_url \
| grep linux_amd64.deb \
| cut -d '"' -f 4 \
| xargs curl -LO \
&& dpkg -i chezmoi_*_linux_amd64.deb && rm chezmoi_*_linux_amd64.deb

echo '> Done'
