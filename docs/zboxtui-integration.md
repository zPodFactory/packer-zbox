# zBox console + zBoxTUI

Installer: **`/sbin/zbox-zboxtui-setup.sh`** (provisioned from
[`files/zbox-zboxtui-setup.sh`](../files/zbox-zboxtui-setup.sh)).

Full operator and security notes: [zBoxTUI INSTALL.md](https://github.com/zPodFactory/zBoxTUI/blob/main/INSTALL.md).

## Layout (with `--enable`)

The appliance ships with the software installed but every VT on stock getty (see
"Deploy-time toggle" below). Once wired via `--enable` (or the OVF property):

| VT | Service | What you get |
|----|---------|----------------|
| **tty1** | kmscon → zBoxTUI | DCUI dashboard (**F2** login, **F12** reboot, **F8** exit app after login) |
| **tty2** | kmscon → agetty | Truecolor login shell (zsh after login) |
| tty3–tty6 | getty | Stock Debian login |

First boot (only when wired): `zbox-init` reads `/etc/zbox/default-console-vt` (`1`)
and switches to **F1**.

**Menu:** Esc/q returns to the dashboard without logging out. F2 login stays valid for
**15 minutes** (same default as sudo’s timestamp); a cached `sudo` timestamp can extend
the session without re-entering the password.

## Usage

```bash
sudo /sbin/zbox-zboxtui-setup.sh --install
sudo /sbin/zbox-zboxtui-setup.sh --enable
sudo /sbin/zbox-zboxtui-setup.sh --disable

# Optional tuning (defaults: fira, 12pt, mocha)
sudo /sbin/zbox-zboxtui-setup.sh --enable --font jetbrains --palette latte --font-size 14
```

`--install` (unattended, used at image build time): installs kmscon + Nerd Font, clones
[zBoxTUI](https://github.com/zPodFactory/zBoxTUI), `uv build` + `pip install` into
`/opt/zboxtui/venv`, copies `packaging/app.conf.sample` and logrotate, writes kmscon
and console wrappers inline, then deletes `/tmp/zboxtui-build`. Console wiring is left
untouched — every VT stays on stock getty.

`--enable`: ensures the software above is installed (skips reinstall if it already is,
so no network access is required when it was baked in at build time), then wires
tty1 → zBoxTUI and tty2 → themed kmscon shell.

`--disable`: restores agetty on all VTs, removes zBoxTUI files, `apt purge kmscon`.

## Deploy-time toggle (OVF property)

The image is built with zBoxTUI **installed but not wired to any console** (see Packer
step below) via the `guestinfo.zboxtui` OVF property (boolean, default `false`,
`postprocess-ova-properties/appliance.xml.template`).

- `files/zbox-init.sh` parses `guestinfo.zboxtui`; only when it is exactly `"True"`
  (capitalized — this is what `govc` itself requires/produces for a boolean property)
  does it run `/sbin/zbox-zboxtui-setup.sh --enable` on first boot, before switching
  consoles. Any other value (including unset/`false`) runs `--disable` instead, which
  purges kmscon and the zBoxTUI venv/files to reclaim the space the image build baked in.
- Set the "Enable zBoxTUI Console" property to `True` at OVF deployment time to wire
  the dashboard onto tty1; leave it unset/`false` to remove zBoxTUI on first boot and
  keep the standard login shell.

## Packer

1. Provisions `files/zbox-zboxtui-setup.sh` → `/sbin/`
2. `scripts/zbox-system.sh` runs `/sbin/zbox-zboxtui-setup.sh --install` (bakes the
   software into the image; console wiring is decided at first boot by `zbox-init.sh`,
   above)

Override clone source at build time:

| Variable | Default |
|----------|---------|
| `ZBOXTUI_GIT_URL` | `https://github.com/zPodFactory/zBoxTUI.git` |
| `ZBOXTUI_GIT_REF` | `main` |
| `NERD_FONT` | `fira` |
| `FONT_SIZE` | `12` |
| `PALETTE` | `mocha` |

## Dashboard on the appliance

The tty1 dashboard lists physical and tunnel interfaces with `[STATIC]`, `[DHCP]`, or
`[UNMANAGED]` tags (Tailscale **tailscale0**, NetBird **wt0**, etc. when present).
See [zBoxTUI README](https://github.com/zPodFactory/zBoxTUI/blob/main/README.md) screenshots `17_dashboard_vpn_interfaces`.
