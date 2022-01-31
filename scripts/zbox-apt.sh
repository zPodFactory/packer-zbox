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

##
## Docker
## 

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Add Docker official repository
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

##
## Hashicorp
## 

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

apt-add-repository \
   "deb [arch=amd64] https://apt.releases.hashicorp.com \
   $(lsb_release -cs) \
   main"

##
## Kubernetes 
## 

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Add Kubernetes official repository
apt-add-repository \
  "deb [arch=amd64] https://apt.kubernetes.io \
  kubernetes-xenial \
  main"

##
## Powershell
##

curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add microsoft official repository
add-apt-repository \
   "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod \
   $(lsb_release -cs) \
   main"

apt-get update

echo '> Done'