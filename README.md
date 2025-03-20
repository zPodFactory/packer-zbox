# zBox appliance

Based on Debian GNU Linux


## Packer setup

Set your `zbox-builder.json` file with the correct parameters from the provided example file.

```bash
cp zbox-builder.json.sample zbox-builder.json
```

Edit the required values in the `zbox-builder.json` file to reflect your builder environment.

```bash
vi zbox-builder.json
```


## Purpose

My personal all-in-one VM for testing & developement

- Fancy zsh prompt shell (oh-my-zsh/posh/custom theme)
- Pre-configured apt sources list for docker,kubernetes,powershell,hashicorp,tailscale
- LVM2 based storage configuration
- Various misc tools

Easily deploy the appliance using the provided OVF Properties

## Repository

Latest 12.x builds are available here:

- https://cloud.tsugliani.fr/ova/zbox-12.8.ova
- https://cloud.tsugliani.fr/ova/zbox-12.9.ova
- https://cloud.tsugliani.fr/ova/zbox-12.10.ova


## Screenshot

![zBox](https://cloud.tsugliani.fr/zbox-defaults.png)
