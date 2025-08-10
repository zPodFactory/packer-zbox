#!/bin/bash -eux

##
## Debian
## Setup all third party APT repositories
##

# Install pre-requisites
apt-get update
apt-get install -y \
  ca-certificates \
  gnupg \
  lsb-release

# Detect Debian codename
debian_codename=$(lsb_release -cs)

# Some third-party repos may lag behind Debian releases.
# Fall back to bookworm for repos that don't publish trixie yet.
hashicorp_codename="$debian_codename"
microsoft_codename="$debian_codename"
if [ "$debian_codename" = "trixie" ]; then
  hashicorp_codename="bookworm"
  microsoft_codename="bookworm"
fi
# Create folder for all new added APT repositories GPG Signing Keys
mkdir -m 0755 -p /etc/apt/keyrings

##
## Docker
##

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker official repository

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${debian_codename} stable" \
| tee /etc/apt/sources.list.d/docker.list

##
## Hashicorp
##

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg

# Add Hashicorp official repository (fallback to bookworm on trixie)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${hashicorp_codename} main" \
| tee /etc/apt/sources.list.d/hashicorp.list

##
## Kubernetes
##

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

# Add Kubernetes official repository

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' \
| tee /etc/apt/sources.list.d/kubernetes.list

##
## Powershell
##

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg

# Add Microsoft official repository (fallback to bookworm on trixie)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-debian-${microsoft_codename}-prod ${microsoft_codename} main" \
| tee /etc/apt/sources.list.d/microsoft.list


##
## Tailscale
##

curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

##
## eza
##

wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list

# Update APT repository package list
apt-get update

echo '> Done'