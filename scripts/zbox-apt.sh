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

echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${debian_codename} stable" \
| tee /etc/apt/sources.list.d/docker.list

##
## Hashicorp
##

curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg

# Add Hashicorp official repository (fallback to bookworm on trixie)
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${debian_codename} main" \
| tee /etc/apt/sources.list.d/hashicorp.list

##
## Kubernetes
##

kubernetes_version=$(curl -L -s https://dl.k8s.io/release/stable.txt | cut -d. -f1-2)
curl -fsSL https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

# Add Kubernetes official repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/ /" \
| tee /etc/apt/sources.list.d/kubernetes.list


##
## Tailscale
##

curl -fsSL "https://pkgs.tailscale.com/stable/debian/${debian_codename}.noarmor.gpg" | gpg --dearmor -o /etc/apt/keyrings/tailscale.gpg

# Add Tailscale official repository
echo "deb [signed-by=/etc/apt/keyrings/tailscale.gpg] https://pkgs.tailscale.com/stable/debian ${debian_codename} main" \
| tee /etc/apt/sources.list.d/tailscale.list


##
## Netbird
##

curl -fsSL https://pkgs.netbird.io/debian/public.key | gpg --dearmor -o /etc/apt/keyrings/netbird.gpg

# Add Netbird official repository
echo "deb [signed-by=/etc/apt/keyrings/netbird.gpg] https://pkgs.netbird.io/debian stable main" \
| tee /etc/apt/sources.list.d/netbird.list


##
## Cloudflare Tunnel
##

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /etc/apt/keyrings/cloudflare-main.gpg

# Add Cloudflare Tunnel official repository
echo "deb [signed-by=/etc/apt/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
| tee /etc/apt/sources.list.d/cloudflared.list

##
## Mise
##

curl -fSs https://mise.en.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise.gpg

# Add Mise official repository
echo "deb [signed-by=/etc/apt/keyrings/mise.gpg] https://mise.en.dev/deb stable main" \
| tee /etc/apt/sources.list.d/mise.list


# Update APT repository package list
apt-get update

echo '> Done'