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
  man \
  vim \
  ccze \
  file \
  htop \
  make \
  tmux \
  tree \
  bzip2 \
  unzip \
  httpie \
  ripgrep \
  colordiff \
  colortail \
  syslog-ng \
  cloud-init

# Debian's syslog-ng-core postinst only registers the sysvinit script (update-rc.d) and
# starts the daemon once through invoke-rc.d; it never enables the systemd unit, so the
# appliance boots with syslog-ng "disabled; preset: enabled" and no /var/log/syslog.
systemctl enable syslog-ng.service


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

echo '> Configuring zBox console + zBoxTUI...'
/sbin/zbox-zboxtui-setup.sh --install

echo '> Done'
