#!/bin/zsh

# Path to the temporary OVF environment file
ZBOX_OVFENV_FILE="/tmp/ovfenv.xml"
# Path to the configuration file
ZBOX_CONFIG_FILE="/etc/zbox.config"

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


log() {
    local message="$1"                           # The message to log
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S') # Current timestamp

    echo "$message"
    # Append the timestamp and message to the CONFIG_FILE
    echo "[$timestamp] $message" >>$ZBOX_CONFIG_FILE
}


# Function to fetch OVF settings
appliance_config_ovf_settings() {
    log "Fetching OVF settings..."
    # Get OVF environment and save to file
    vmtoolsd --cmd 'info-get guestinfo.ovfEnv' >$ZBOX_OVFENV_FILE

    # Extract only the first PropertySection (direct child of Environment)
    # This is necessary when the VM is deployed inside a vApp, where the OVF
    # environment contains multiple PropertySection elements (one for each VM).
    # The first PropertySection belongs to the current VM.
    FIRST_PROP_SECTION=$(awk '/<PropertySection>/,/<\/PropertySection>/{print; if(/<\/PropertySection>/) exit}' $ZBOX_OVFENV_FILE)

    # Parse OVF properties from the extracted section
    OVF_HOSTNAME=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.hostname" oe:value="\([^"]*\).*/\1/p')
    OVF_DNS=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.dns" oe:value="\([^"]*\).*/\1/p')
    OVF_DOMAIN=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.domain" oe:value="\([^"]*\).*/\1/p')
    OVF_GATEWAY=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.gateway" oe:value="\([^"]*\).*/\1/p')
    OVF_IPADDRESS=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.ipaddress" oe:value="\([^"]*\).*/\1/p')
    OVF_NETPREFIX=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.netprefix" oe:value="\([^"]*\).*/\1/p')
    OVF_PASSWORD=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.password" oe:value="\([^"]*\).*/\1/p')
    OVF_SSHKEY=$(echo "$FIRST_PROP_SECTION" | sed -n 's/.*Property oe:key="guestinfo.sshkey" oe:value="\([^"]*\).*/\1/p')

    # Check for cloud-init configuration conflict using direct vmtoolsd queries
    OVF_METADATA=$(vmtoolsd --cmd 'info-get guestinfo.metadata' 2>/dev/null)
    OVF_USERDATA=$(vmtoolsd --cmd 'info-get guestinfo.userdata' 2>/dev/null)

    # Check for cloud-init configuration conflict
    if [[ -n "$OVF_METADATA" ]] || [[ -n "$OVF_USERDATA" ]]; then
        log "=========================================="
        log "CLOUD-INIT DEPLOYMENT DETECTED"
        log "=========================================="
        log "Executing cloud-init..."
        log "=========================================="

        # Clean up cloud-init
        cloud-init clean --logs | tee -a $ZBOX_CONFIG_FILE

        # Init cloud-init
        cloud-init init --local | tee -a $ZBOX_CONFIG_FILE
        cloud-init init | tee -a $ZBOX_CONFIG_FILE

        # As we are bypassing "normal" systemd/cloud-init initialization
        # we need to bring up the network manually
        ifup eth0 | tee -a $ZBOX_CONFIG_FILE

        # Run cloud-init modules
        cloud-init modules --mode=config | tee -a $ZBOX_CONFIG_FILE
        cloud-init modules --mode=final | tee -a $ZBOX_CONFIG_FILE

        # Disable cloud-init
        touch /etc/cloud/cloud-init.disabled

        # Clean up tty1 service (cosmetic artefacts on console)
        systemctl restart getty@tty1.service

        # Clean up temporary file before exiting
        if [[ -f "$ZBOX_OVFENV_FILE" ]]; then
            rm -f "$ZBOX_OVFENV_FILE"
        fi

        exit 0
    else
        log "=========================================="
        log "ZBOX-INIT DEPLOYMENT DETECTED"
        log "=========================================="
        log "FQDN: $OVF_HOSTNAME.$OVF_DOMAIN"
        log "DNS: $OVF_DNS"
        log "Network: $OVF_IPADDRESS/$OVF_NETPREFIX"
        log "Gateway: $OVF_GATEWAY"
        log "SSH Key: $OVF_SSHKEY"
        log "=========================================="
    fi
}


# Function to configure the network
appliance_config_network() {
    log "Configuring network..."

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
    log "Configuring hostname..."

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

    # Add SSH key
    if [[ -n "$OVF_SSHKEY" ]]; then
        echo "$OVF_SSHKEY" >> /root/.ssh/authorized_keys
        log "SSH key added to authorized_keys."
    else
        log "Warning: No SSH key provided in OVF properties."
    fi
}


# Function to create and configure zadmin user
appliance_config_user() {
    local ZADMIN_USER="zadmin"

    log "Configuring user $ZADMIN_USER..."

    # Check if user already exists
    if id "$ZADMIN_USER" &>/dev/null; then
        log "User $ZADMIN_USER already exists, skipping creation."
        return 0
    fi

    # Create user with zsh shell (adduser will use /etc/skel for home directory)
    adduser --disabled-password --gecos "zBox Admin" --shell /bin/zsh "$ZADMIN_USER"
    log "User $ZADMIN_USER created."

    # Add to sudo group
    usermod -aG sudo "$ZADMIN_USER"
    log "User $ZADMIN_USER added to sudo group."

    # Configure NOPASSWD sudo access
    echo "$ZADMIN_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$ZADMIN_USER
    chmod 440 /etc/sudoers.d/$ZADMIN_USER
    log "NOPASSWD sudo access configured for $ZADMIN_USER."

    # Set password (same as root)
    if [[ -n "$OVF_PASSWORD" ]]; then
        echo "$ZADMIN_USER:$OVF_PASSWORD" | chpasswd
        log "Password set for $ZADMIN_USER."
    else
        log "Warning: No password provided for $ZADMIN_USER."
    fi

    # Add SSH key (same as root)
    if [[ -n "$OVF_SSHKEY" ]]; then
        mkdir -p /home/$ZADMIN_USER/.ssh
        chmod 700 /home/$ZADMIN_USER/.ssh
        echo "$OVF_SSHKEY" >> /home/$ZADMIN_USER/.ssh/authorized_keys
        chmod 600 /home/$ZADMIN_USER/.ssh/authorized_keys
        chown -R $ZADMIN_USER:$ZADMIN_USER /home/$ZADMIN_USER/.ssh
        log "SSH key added for $ZADMIN_USER."
    else
        log "Warning: No SSH key provided for $ZADMIN_USER."
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
    appliance_config_user

    # Clean up temporary files
    if [[ -f "$ZBOX_OVFENV_FILE" ]]; then
        rm -vf "$ZBOX_OVFENV_FILE"
        log "Cleaned up temporary OVF environment file."
    fi

    echo "zBox Setup complete"
}

# Invoke the main function
main