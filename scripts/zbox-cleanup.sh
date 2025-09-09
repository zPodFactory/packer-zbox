#!/bin/bash -eux

##
## Debian Cleanup
## Cleaning VM before OVA Export
##

# Disable eth0 configuration for firstboot
cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
EOF

duf -only local

# Clean up
echo '> Removing unnecessary packages...'
apt-get remove -y linux-headers-$(uname -r) build-essential make
apt-get purge -y $(dpkg --list | grep '^rc' | awk '{print $2}')

# Remove any remaining kernel from installation (~400MB)
apt-get purge -y $(dpkg -l | egrep 'linux-image-[0-9]' | grep -v $(uname -r) | awk '{ print $2 }')

echo '> Removing package manager unused files'
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y


echo '> Removing unused locales...'
DEBIAN_FRONTEND=noninteractive apt-get -y install localepurge
sed -i -e 's|^USE_DPKG|#USE_DPKG|' /etc/locale.nopurge
localepurge
apt-get purge -y localepurge

# cleanup installer resolv.conf
echo ""  > /etc/resolv.conf

# Cleanup log files
echo '> Removing Log files...'
cat /dev/null > /var/log/wtmp 2>/dev/null
logrotate -f /etc/logrotate.conf 2>/dev/null
find /var/log -type f -delete
rm -f /var/lib/dhcp/*

# Zero out the free space to save space in the final image, blocking 'til
# written otherwise, the disk image won't be zeroed, and/or Packer will try to
# kill the box while the disk is still full and that's bad.  The dd will run
# 'til failure, so (due to the 'set -e' above), ignore that failure.  Also,
# really make certain that both the zeros and the file removal really sync; the
# extra sleep 1 and sync shouldn't be necessary, but...)

echo '> Zeroing device to reduce resulting VMDK & OVA export...'
dd if=/dev/zero of=/EMPTY bs=16M || true; sync; sleep 1; sync
rm -f /EMPTY; sync; sleep 1; sync

duf -only local

# Cleanup cloud-init for firstboot
cloud-init clean

# Disable cloud-init for firstboot (let zbox-init.sh handle it)
touch /etc/cloud/cloud-init.disabled

echo '> Done'
