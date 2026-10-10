# Changelog

Notable changes to the zBox appliance, newest first. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow the **Debian point
release** the appliance is built on: `13.7` is the zBox built from `zbox-13.7.json`, and its
git tag is `v13.7`. A rebuild of the same Debian release with appliance-only changes may take a
third digit (`v13.7.1`); it still reads `zbox-13.7.json`.

Entries describe what changed for the person deploying the appliance: tools added or removed,
first-boot behaviour, OVF properties, disk layout. The commit history has the reasoning.

**Cutting a release.** Changes land under `[Unreleased]` as they are made. When a new Debian
point release is out: create `zbox-X.Y.json` (ISO URL and sha256), build the OVA with
`./build-zbox.sh`, publish it, then `python3 tools/release.py X.Y --push` does the rest:
`[Unreleased]` becomes `[X.Y] — date`, `build-zbox.sh` is pointed at the new var file, the
commit is tagged `vX.Y` and pushed, and the tag publishes this file's section as the GitHub
release note, with the ISO, its checksum and the OVA link above it
(`.github/workflows/release.yml`, `tools/release_notes.py`). The script refuses a dirty tree, an
empty `[Unreleased]` (`--from-commits` fills it from the commits), a version not above the last
tag, a var file that does not exist yet, and any string from the local `.release-denylist`;
`--check` runs the same rules, and CI runs it on every push. Preview a note with
`python3 tools/release_notes.py X.Y`.

## [Unreleased]

### Changed

- **Releases follow the shared zPodFactory standard.** `tools/release.py` (cut, `--check`,
  `--draft`, `--from-commits`) and `tools/release_notes.py` are the same files as in every other
  repository, with a configuration block at the top: here the version is the var file
  `build-zbox.sh` names, and the note carries the ISO, its checksum and the OVA link.
  `tools/README.md` explains the release in a page. The tag is created by the cut, on the
  workstation, never by a workflow.

### Fixed

- **syslog-ng runs at boot.** Debian 13's `syslog-ng-core` package registers only its sysvinit
  script and never enables the systemd unit, so the appliance came up with the unit
  `disabled` and no `/var/log/syslog`. The system script now enables it explicitly.
- **kmscon uses the software renderer** (`no-hwaccel`). On the VMware virtual GPU the GL
  renderer fails every glyph upload and floods syslog and the journal with `text_gltex`
  warnings (~40k/s) while burning a CPU. Existing appliances: set `no-hwaccel` in
  `/etc/kmscon/kmscon.conf` and restart `kmsconvt@tty1` and `kmsconvt@tty2`.

## [13.7] — 2026-09-24

### Added
- **zBoxTUI on tty1 is opt-in per deployment** via the `guestinfo.zboxtui` OVF property
  (default `False`). The setup script is split into `--install` (bakes kmscon and zBoxTUI into
  the image at build time, every VT stays on stock getty) and `--enable` (wires tty1/tty2 at
  first boot, no network needed).
- `guestinfo.zboxtui=False` now actively runs `--disable` at first boot, purging kmscon and the
  zBoxTUI venv so a deployment that does not want the console does not carry its weight.

### Changed
- Built on **Debian 13.7**.
- Disk controller switched from LSI Logic to **PVSCSI**; the installer kernel already ships
  `vmw_pvscsi`, so the preseed is unchanged.
- zBoxTUI is installed with `uv` again. Two bugs in that path are fixed: `uv` landed outside
  `PATH`, and installer progress output corrupted the captured wheel path. `uv` and its cache are
  removed after use so neither ships in the image.
- `zbox-zboxtui-setup.sh --disable` restores the stock Debian getty layout exactly: only
  `getty@tty1` enabled, tty2–6 started on demand by autovt.

### Removed
- `wakey`, `btop`, `mise` (its apt repo stays configured, `apt install mise` is one command
  away) and `pure-ftpd`.

## [13.6] — 2026-07-15

### Changed
- Built on **Debian 13.6**.
- `build-zbox.sh` makes the exported OVA world-readable (`chmod 644`).

## [13.5] — 2026-05-17

### Added
- [chezmoi](https://chezmoi.io/) for dotfiles management.
- `mise` runtime version manager and its apt repo.

### Changed
- Built on **Debian 13.5**.
- apt package lists refactored; tmux tuned for true color; oh-my-zsh plugins enabled.
- `atuin` installs straight into `/usr/local/bin` through the installer's non-interactive mode.

### Removed
- `direnv` (replaced by `mise`).

## [13.4] — 2026-03-18

### Added
- Cloudflare Tunnel (`cloudflared`) apt repository.
- `xfr` (iperf3 alternative with a live TUI), `cull` (disk usage TUI), `surge` download manager,
  `ttl`.
- `eza` installed directly as a binary.

### Changed
- Built on **Debian 13.4**.
- HashiCorp repo uses the native `trixie` codename; the bookworm fallback is gone.
- Kubernetes apt repo follows the current stable minor automatically instead of a pinned
  `v1.33`.
- `surge` is fetched from its latest GitHub release instead of a pinned version.

### Fixed
- OVF properties are read correctly when the VM is deployed inside a vApp.

### Removed
- PowerShell and the Microsoft apt repository, `nfs-kernel-server`, and the old 12.x var files.

## [13.3] — 2026-01-10

### Added
- Shell configuration is global: oh-my-zsh, oh-my-posh themes and tmux plugins live under
  `/usr/share`, `atuin` under `/usr/local/bin`, and `/etc/skel` symlinks give new users the same
  setup. Auto-update stays on for root only.
- `zadmin` user created on first boot with passwordless sudo.
- `CLAUDE.md` project documentation.

### Changed
- Built on **Debian 13.3**.

## [13.2] — 2026-01-02

### Added
- `snitch` (network connection inspector) and `witr`.
- `gping` replaces the previous ping tooling.

### Changed
- Built on **Debian 13.2**.
- First boot moved from `rc.local` to a proper `zbox-init` systemd unit, which drives cloud-init
  directly when a cloud-init payload is present and keeps it disabled otherwise, avoiding
  conflicts between the two.
- VMware guest customization through tools is disabled; OVF properties or cloud-init are the way
  to configure the appliance.
- oh-my-posh theme adapted to the upstream removal of the command-type block.
- README documents both deployment options with screenshots.

## [13.1] — 2025-09-08

### Added
- cloud-init support.
- `ripgrep`.

### Changed
- Built on **Debian 13.1**.
- `duf` alias updated.

## [13.0] — 2025-08-10

### Added
- **Debian 13 (trixie) support**: `zbox-13.0.json`, cloud kernel with a sysctl drop-in, Tailscale
  trixie repository, and bookworm fallbacks for third-party repositories that did not publish
  trixie packages yet (HashiCorp, Microsoft).

### Changed
- Built on **Debian 13.0**.
