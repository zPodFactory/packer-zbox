# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

packer-zbox is a Packer-based project that builds a customized Debian Linux VM appliance (zBox) as an OVA. The appliance is designed for development and testing with pre-configured tools, shell enhancements, optional **zBoxTUI** on the physical console (tty1), and deployment via OVF properties or cloud-init.

## Build Commands

```bash
# Build the appliance (requires VMware ESXi builder environment)
./build-zbox.sh

# The build script runs:
# packer build --var-file="zbox-builder.json" --var-file="zbox-13.7.json" zbox.json
```

**Prerequisites:**
- Copy `zbox-builder.json.sample` to `zbox-builder.json` and configure ESXi builder host settings
- Requires a VMware ESXi environment for Packer to build on

## Architecture

### Packer Configuration

- `zbox.json` - Main Packer template defining the VMware ISO builder, provisioners, and post-processors
- `zbox-X.Y.json` - Version-specific variables (Debian version, ISO URL, checksums); current build uses **`zbox-13.7.json`**
- `zbox-builder.json` - Builder environment config (ESXi host, credentials, datastore)

### Build Flow

1. **Boot & Install**: Packer boots Debian netinst ISO on ESXi, uses `http/preseed.cfg` for automated installation with LVM partitioning
2. **Provisioning**: Runs shell scripts from `scripts/` in order:
   - `zbox-update.sh` - apt update and upgrade to latest packages
   - `zbox-apt.sh` - Adds third-party repos (Docker, Hashicorp, Kubernetes, Tailscale, Netbird, Cloudflare Tunnel)
   - `zbox-system.sh` - Installs system utilities (jq, bat, duf, eza, fzf, ripgrep, htop, fx, chezmoi, etc.), cloud-init, and **`/sbin/zbox-zboxtui-setup.sh --install`**
   - `zbox-network.sh` - Installs network utilities (gping, doggo, tcpdump, wireguard, snitch, witr, ttl, xfr, surge, etc.)
   - `zbox-storage.sh` - Installs storage utilities (lftp, cull)
   - `zbox-settings.sh` - Configures DNS resolver, IP forwarding, SSH banner, and enables zbox-init service
   - `zbox-shell.sh` - Installs zsh, oh-my-zsh, oh-my-posh, tmux with catppuccin, zoxide, atuin
   - `zbox-vmware.sh` - Installs open-vm-tools and cloud-guest-utils, disables guest customization
   - `zbox-cleanup.sh` - Removes unnecessary packages, zeroes disk, cleans logs for smaller OVA export
3. **File Provisioning**: Copies config files from `files/` (`zbox-init` service, `zbox-zboxtui-setup.sh`, zshrc, tmux.conf, oh-my-posh theme)
4. **Post-processing**: `postprocess-ova-properties/add_ovf_properties.sh` injects OVF properties from `appliance.xml.template` and converts to OVA

### zBoxTUI console (tty1)

See **[docs/zboxtui-integration.md](docs/zboxtui-integration.md)** and [zBoxTUI INSTALL.md](https://github.com/zPodFactory/zBoxTUI/blob/main/INSTALL.md).

- `files/zbox-zboxtui-setup.sh` → `/sbin/zbox-zboxtui-setup.sh`
- `zbox-system.sh` runs `--enable` at image build time (clones [zBoxTUI](https://github.com/zPodFactory/zBoxTUI) @ `main` by default)
- **tty1**: kmscon → zBoxTUI; **tty2**: kmscon → login shell; tty3–6: stock getty

### Runtime Initialization

- `files/zbox-init.sh` - First-boot initialization script (installed as systemd service)
  - Detects deployment method (OVF properties vs cloud-init)
  - Configures networking, hostname, storage expansion (LVM grow), credentials
  - Switches to the default console VT (`/etc/zbox/default-console-vt`, usually **1**)
  - `--extend-disk` flag runs storage expansion only (no full first-boot path)

### Deployment Methods

1. **OVF Properties**: VM deployed with guestinfo properties (hostname, IP, gateway, DNS, password, SSH key)
2. **Cloud-init**: VM deployed with guestinfo.metadata and guestinfo.userdata (base64+gzip encoded)

## Key Directories

- `scripts/` - Provisioning scripts run during build
- `files/` - Config files copied to the appliance (including `zbox-zboxtui-setup.sh`)
- `http/` - Contains preseed.cfg for Debian installer
- `postprocess-ova-properties/` - OVA post-processing for OVF property injection
- `docs/` - Console integration notes (`zboxtui-integration.md`)

## Version Management

To create a new version:
1. Copy an existing `zbox-X.Y.json` file with new version number
2. Update ISO URL and checksum for the new Debian release
3. Update `build-zbox.sh` to reference the new version file
4. `python3 tools/release.py X.Y --push` (see Releases below)

## Releases

- Versions follow the Debian point release: `zbox-13.7.json` is tag `v13.7` is release `v13.7`.
- Every change gets a line under `[Unreleased]` in `CHANGELOG.md`: what changed for the person
  deploying the appliance, and why in a clause.
- A release is one command: `python3 tools/release.py X.Y --push` (`--dry-run` first). Create `zbox-X.Y.json`
  and build the OVA first; the cut moves the heading, points `build-zbox.sh` at the var file, commits, tags `vX.Y`, pushes; the tag then publishes the
  section as the GitHub release through `.github/workflows/release.yml`.
- `python3 tools/release.py --check` is what CI runs on every push: shipped version equals the
  newest section, every tag has a section, nothing local is tracked. Keep the forbidden-string
  list in `.release-denylist` (git-ignored) for the names that must never enter the history.
- Never tag by hand, never edit a release on GitHub: fix the changelog and re-run the workflow
  (`workflow_dispatch`, blank version republishes every tag).
