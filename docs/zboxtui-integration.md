# zBox console + zBoxTUI

Installer: **`/sbin/zbox-zboxtui-setup.sh`** (provisioned from
[`files/zbox-zboxtui-setup.sh`](../files/zbox-zboxtui-setup.sh)).

Full operator and security notes: [zBoxTUI INSTALL.md](https://github.com/zPodFactory/zBoxTUI/blob/main/INSTALL.md).

## Layout (default `--enable`)

| VT | Service | What you get |
|----|---------|----------------|
| **tty1** | kmscon → zBoxTUI | DCUI dashboard (**F2** login, **F12** reboot, **F8** exit app after login) |
| **tty2** | kmscon → agetty | Truecolor login shell (zsh after login) |
| tty3–tty6 | getty | Stock Debian login |

First boot: `zbox-init` reads `/etc/zbox/default-console-vt` (`1`) and switches to **F1**.

**Menu:** Esc/q returns to the dashboard without logging out. F2 login stays valid for
**15 minutes** (same default as sudo’s timestamp); a cached `sudo` timestamp can extend
the session without re-entering the password.

## Usage

```bash
sudo /sbin/zbox-zboxtui-setup.sh --enable
sudo /sbin/zbox-zboxtui-setup.sh --disable

# Optional tuning (defaults: fira, 12pt, mocha)
sudo /sbin/zbox-zboxtui-setup.sh --enable --font jetbrains --palette latte --font-size 14
```

`--enable` (unattended): installs kmscon + Nerd Font, clones
[zBoxTUI](https://github.com/zPodFactory/zBoxTUI), `uv build` + `pip install` into
`/opt/zboxtui/venv`, copies `packaging/app.conf.sample` and logrotate, writes kmscon
and console wrappers inline, then deletes `/tmp/zboxtui-build`.

`--disable`: restores agetty on all VTs, removes zBoxTUI files, `apt purge kmscon`.

## Packer

1. Provisions `files/zbox-zboxtui-setup.sh` → `/sbin/`
2. `scripts/zbox-system.sh` runs `/sbin/zbox-zboxtui-setup.sh --enable`

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
