#!/bin/zsh

# Parse command line arguments
EXTEND_DISK_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --extend-disk)
            EXTEND_DISK_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--extend-disk]"
            exit 1
            ;;
    esac
done

ZBOX_OVFENV_FILE="/tmp/ovfenv.xml"
# Path to the configuration file
ZBOX_CONFIG_FILE="/etc/zbox.config"

log() {
    local message="$1"                           # The message to log
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S') # Current timestamp

    echo "$message"
    # Append the timestamp and message to the CONFIG_FILE
    echo "[$timestamp] $message" >>$ZBOX_CONFIG_FILE
}

# Function to apply OVF settings
appliance_config_ovf_settings() {
    log "Applying OVF settings..."
    # Get OVF environment and save to file
    vmtoolsd --cmd 'info-get guestinfo.ovfEnv' >$ZBOX_OVFENV_FILE

    # Parse OVF properties using sed (similar to zpodfactory.sh approach)
    OVF_HOSTNAME=$(sed -n 's/.*Property oe:key="guestinfo.hostname" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_DNS=$(sed -n 's/.*Property oe:key="guestinfo.dns" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_DOMAIN=$(sed -n 's/.*Property oe:key="guestinfo.domain" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_GATEWAY=$(sed -n 's/.*Property oe:key="guestinfo.gateway" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_IPADDRESS=$(sed -n 's/.*Property oe:key="guestinfo.ipaddress" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_NETPREFIX=$(sed -n 's/.*Property oe:key="guestinfo.netprefix" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_PASSWORD=$(sed -n 's/.*Property oe:key="guestinfo.password" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)
    OVF_SSHKEY=$(sed -n 's/.*Property oe:key="guestinfo.sshkey" oe:value="\([^"]*\).*/\1/p' $ZBOX_OVFENV_FILE)

    clear
    log "========== OVF Settings =========="
    log "FQDN: $OVF_HOSTNAME.$OVF_DOMAIN"
    log "DNS: $OVF_DNS"
    log "Network: $OVF_IPADDRESS/$OVF_NETPREFIX"
    log "Gateway: $OVF_GATEWAY"
    log "SSH Key: $OVF_SSHKEY"
    log "=================================="
}

# Function to configure the network
appliance_config_network() {
    log "Configuring the network..."

    # Stop networking service first
    systemctl stop networking

    # Create /etc/network/interfaces file
    if [[ -n "$OVF_IPADDRESS" ]]; then
        # Static network configuration
        cat <<EOF >/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address $OVF_IPADDRESS/$OVF_NETPREFIX
    gateway $OVF_GATEWAY
    dns-nameservers $OVF_DNS
EOF
    else
        # DHCP configuration
        cat <<EOF >/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF
    fi

    # Start networking service
    systemctl start networking
    log "Networking configured and restarted."
}

# Function to configure the host
appliance_config_host() {
    log "Configuring the hostname..."

    # Set the hostname
    hostnamectl set-hostname $OVF_HOSTNAME

    # Create /etc/hosts file for dnsmasq expand-hosts directive
    if [[ -n "$OVF_HOSTNAME" && -n "$OVF_IPADDRESS" && -n "$OVF_DOMAIN" ]]; then
        cat <<EOF >/etc/hosts
127.0.0.1       localhost
$OVF_IPADDRESS  $OVF_HOSTNAME.$OVF_DOMAIN    $OVF_HOSTNAME
EOF
        log "Hostname and /etc/hosts configured."
    else
        log "Warning: Missing hostname, IP address, or domain for /etc/hosts configuration."
    fi
}

# Function to configure storage
appliance_config_storage() {
    log "Configuring storage..."

    # Display disk usage before extending partitions
    log "Disk usage before extending partitions:"
    duf -only local

    # Rescan the disk (detect size change)
    echo 1 > /sys/class/block/sda/device/rescan

    # Grow partition 2 on /dev/sda
    if growpart /dev/sda 2; then
        log "Successfully extended partition 2 on /dev/sda."
    else
        log "Failed to extend partition 2 on /dev/sda. Exiting..."
        return 1
    fi

    # Grow partition 5 on /dev/sda
    if growpart /dev/sda 5; then
        log "Successfully extended partition 5 on /dev/sda."
    else
        log "Failed to extend partition 5 on /dev/sda. Exiting..."
        return 1
    fi

    # Resize the physical volume
    if pvresize /dev/sda5; then
        log "Successfully resized physical volume /dev/sda5."
    else
        log "Failed to resize physical volume /dev/sda5. Exiting..."
        return 1
    fi

    # Extend the logical volume to use all available free space
    if lvextend -l +100%FREE /dev/vg/root; then
        log "Successfully extended logical volume /dev/vg/root."
    else
        log "Failed to extend logical volume /dev/vg/root. Exiting..."
        return 1
    fi

    # Resize the filesystem
    if resize2fs /dev/vg/root; then
        log "Successfully resized filesystem on /dev/vg/root."
    else
        log "Failed to resize filesystem on /dev/vg/root. Exiting..."
        return 1
    fi

    # Display disk usage
    log "Disk usage after resizing:"
    duf -only local
}

# Function to configure credentials
appliance_config_credentials() {
    log "Configuring credentials..."

    # Update root password
    if [[ -n "$OVF_PASSWORD" ]]; then
        echo "root:$OVF_PASSWORD" | chpasswd
        log "Root password updated."
    else
        log "Warning: No password provided in OVF properties."
    fi

    # Update SSH key
    if [[ -n "$OVF_SSHKEY" ]]; then
        # Ensure .ssh directory exists
        mkdir -p /root/.ssh
        echo "$OVF_SSHKEY" >> /root/.ssh/authorized_keys
        log "SSH key added to authorized_keys."
    else
        log "Warning: No SSH key provided in OVF properties."
    fi
}



# Main execution logic
main() {
    if [[ "$EXTEND_DISK_MODE" == "true" ]]; then
        appliance_config_storage
        return
    fi

    # Check if the configuration file already exists
    if [[ -f "$ZBOX_CONFIG_FILE" ]]; then
        echo "$ZBOX_CONFIG_FILE exists. This script has already been executed. Exiting..."
        exit 0
    fi

    # Execute configuration functions
    appliance_config_ovf_settings
    appliance_config_network
    appliance_config_host
    appliance_config_storage
    appliance_config_credentials

    # Mark the setup as complete by creating the configuration file
    touch "$ZBOX_CONFIG_FILE"
    echo "Setup complete. Configuration file created at $ZBOX_CONFIG_FILE."
}

# Invoke the main function
main