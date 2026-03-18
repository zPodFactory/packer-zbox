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
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${debian_codename} main" \
| tee /etc/apt/sources.list.d/hashicorp.list

##
## Kubernetes
##

kubernetes_version=$(curl -L -s https://dl.k8s.io/release/stable.txt | cut -d. -f1-2)
curl -fsSL https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes official repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/ /" \
| tee /etc/apt/sources.list.d/kubernetes.list


##
## Tailscale
##

curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list


##
## Netbird
##

curl -sSL https://pkgs.netbird.io/debian/public.key | gpg --dearmor --output /usr/share/keyrings/netbird-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' | tee /etc/apt/sources.list.d/netbird.list


##
## Cloudflare Tunnel
##

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /etc/apt/keyrings/cloudflare-main.gpg
echo 'deb [signed-by=/etc/apt/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list

# Update APT repository package list
apt-get update

echo '> Done'