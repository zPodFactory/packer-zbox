#!/bin/bash -eux

##
## Debian Updates
## Upgrade to latest packages
##

echo '> Installing Debian updates...'

apt-get update
apt-get upgrade -y

echo '> Done'