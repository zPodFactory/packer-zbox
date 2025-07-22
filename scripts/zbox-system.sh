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
  exa \
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
  colordiff \
  colortail \
  syslog-ng

#
# Install lazydocker
# https://github.com/jesseduffield/lazydocker
#
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
mv $HOME/.local/bin/lazydocker /usr/local/bin

#
# Install fx (JSON tool)
# https://github.com/antonmedv/fx
#
curl https://fx.wtf/install.sh | sh

#
# Install ssm (ssh connection manager)
# https://github.com/lfaoro/ssm?tab=readme-ov-file
#
wget -qO- https://github.com/lfaoro/ssm/raw/main/scripts/get.sh | bash
chown root:root /usr/local/bin/ssm


echo '> Done'
