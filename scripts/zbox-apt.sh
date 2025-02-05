#!/bin/bash -eux

##
## Debian
## Setup all third party APT repositories
##

# Install pre-requisites
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common

# Create folder for all new added APT repositories GPG Signing Keys
mkdir -m 0755 -p /etc/apt/keyrings

##
## Docker
##

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker official repository

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list

##
## Hashicorp
##

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg

# Add Hashicorp official reposiroty
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
| tee /etc/apt/sources.list.d/hashicorp.list

##
## Kubernetes
##

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Add Kubernetes official repository

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
| tee /etc/apt/sources.list.d/kubernetes.list

##
## Powershell
##

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg

# Add microsoft official repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" \
| tee /etc/apt/sources.list.d/microsoft.list


##
## Tailscale
##

curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

##
## eza
##

wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list

# Update APT repository package list
apt-get update

echo '> Done'