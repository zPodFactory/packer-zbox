# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

packer-zbox is a Packer-based project that builds a customized Debian Linux VM appliance (zBox) as an OVA. The appliance is designed for development and testing with pre-configured tools, shell enhancements, and deployment options via OVF properties or cloud-init.

## Build Commands

```bash
# Build the appliance (requires VMware ESXi builder environment)
./build-zbox.sh

# The build script runs:
# packer build --var-file="zbox-builder.json" --var-file="zbox-13.2.json" zbox.json
```

**Prerequisites:**
- Copy `zbox-builder.json.sample` to `zbox-builder.json` and configure ESXi builder host settings
- Requires a VMware ESXi environment for Packer to build on

## Architecture

### Packer Configuration

- `zbox.json` - Main Packer template defining the VMware ISO builder, provisioners, and post-processors
- `zbox-X.Y.json` - Version-specific variables (Debian version, ISO URL, checksums)
- `zbox-builder.json` - Builder environment config (ESXi host, credentials, datastore)

### Build Flow

1. **Boot & Install**: Packer boots Debian netinst ISO on ESXi, uses `http/preseed.cfg` for automated installation with LVM partitioning
2. **Provisioning**: Runs shell scripts from `scripts/` in order:
   - `zbox-update.sh` - Initial apt update
   - `zbox-apt.sh` - Adds third-party repos (Docker, Hashicorp, Kubernetes, Tailscale, PowerShell, eza)
   - `zbox-system.sh` - Installs utilities (jq, bat, fzf, ripgrep, htop, etc.)
   - `zbox-network.sh` - Network configuration
   - `zbox-storage.sh` - LVM storage setup
   - `zbox-settings.sh` - System settings
   - `zbox-shell.sh` - Installs zsh, oh-my-zsh, oh-my-posh, tmux with catppuccin, zoxide, atuin
   - `zbox-vmware.sh` - VMware tools
   - `zbox-cleanup.sh` - Cleanup for smaller image
3. **File Provisioning**: Copies config files from `files/` (zshrc, tmux.conf, oh-my-posh theme, init service)
4. **Post-processing**: `postprocess-ova-properties/add_ovf_properties.sh` injects OVF properties from `appliance.xml.template` and converts to OVA

### Runtime Initialization

- `files/zbox-init.sh` - First-boot initialization script (installed as systemd service)
  - Detects deployment method (OVF properties vs cloud-init)
  - Configures networking, hostname, storage expansion, credentials
  - `--extend-disk` flag for on-demand LVM disk extension

### Deployment Methods

1. **OVF Properties**: VM deployed with guestinfo properties (hostname, IP, gateway, DNS, password, SSH key)
2. **Cloud-init**: VM deployed with guestinfo.metadata and guestinfo.userdata (base64+gzip encoded)

## Key Directories

- `scripts/` - Provisioning scripts run during build
- `files/` - Config files copied to the appliance
- `http/` - Contains preseed.cfg for Debian installer
- `postprocess-ova-properties/` - OVA post-processing for OVF property injection

## Version Management

To create a new version:
1. Copy an existing `zbox-X.Y.json` file with new version number
2. Update ISO URL and checksum for the new Debian release
3. Update `build-zbox.sh` to reference the new version file
