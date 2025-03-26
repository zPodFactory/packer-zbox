packer {
  required_plugins {
    vmware = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "hostname" {
  type = string
  default = ""
}

variable "iso_checksum_type" {
  type = string
  default = ""
}

variable "iso_checksum" {
  type = string
  default = ""
}

variable "iso_url" {
  type = string
  default = ""
}

variable "vm_name" {
  type = string
  default = ""
}

variable "builder_host_datastore" {
  type = string
  default = ""
}

variable "builder_host" {
  type = string
  default = ""
}

variable "builder_host_password" {
  type = string
  sensitive = true
  default = ""
}

variable "builder_host_username" {
  type = string
  default = ""
}

variable "guest_password" {
  type = string
  sensitive = true
  default = ""
}

variable "guest_username" {
  type = string
  default = ""
}

variable "builder_host_portgroup" {
  type = string
  default = ""
}

variable "ramsize" {
  type = string
  default = ""
}

variable "numvcpus" {
  type = string
  default = ""
}

variable "version" {
  type = string
  default = ""
}

source "vmware-iso" "zbox" {
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US <wait>",
    "auto <wait>",
    "net.ifnames=0 <wait>",
    "biosdevname=0 <wait>",
    "locale=en_US <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/choose_interface=eth0 <wait>",
    "netcfg/get_hostname=${var.hostname} <wait>",
    "netcfg/get_domain=zbox.lab <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]
  boot_wait             = "10s"
  disk_size             = 51200
  disk_type_id          = "zeroedthick"
  format                = "ovf"
  headless              = false
  http_directory        = "http"
  iso_checksum          = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url               = "${var.iso_url}"
  ovftool_options       = ["--noImageFiles"]
  remote_datastore      = "${var.builder_host_datastore}"
  remote_host           = "${var.builder_host}"
  remote_password       = "${var.builder_host_password}"
  remote_type           = "esx5"
  remote_username       = "${var.builder_host_username}"
  shutdown_command      = "/sbin/shutdown -Ph now"
  shutdown_timeout      = "10s"
  insecure_connection   = true
  vnc_over_websocket    = true
  skip_compaction       = true
  ssh_password          = "${var.guest_password}"
  ssh_port              = 22
  ssh_timeout           = "60m"
  ssh_username          = "${var.guest_username}"
  version               = 14
  vm_name               = "${var.vm_name}"
  vmdk_name             = "${var.vm_name}-disk0"
  vnc_disable_password  = true
  output_directory      = "output-${var.vm_name}"

  vmx_data = {
    "ethernet0.addressType"     = "generated"
    "ethernet0.networkName"     = "${var.builder_host_portgroup}"
    "ethernet0.present"         = "TRUE"
    "ethernet0.startConnected"  = "TRUE"
    "ethernet0.virtualDev"      = "vmxnet3"
    "ethernet0.wakeOnPcktRcv"   = "FALSE"
    "memsize"                   = "${var.ramsize}"
    "numvcpus"                  = "${var.numvcpus}"
  }
}

build {
  sources = ["source.vmware-iso.zbox"]

  provisioner "file" {
    source      = "files/debian-init.py"
    destination = "/sbin/debian-init.py"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts = [
      "scripts/zbox-update.sh",
      "scripts/zbox-apt.sh",
      "scripts/zbox-system.sh",
      "scripts/zbox-network.sh",
      "scripts/zbox-storage.sh",
      "scripts/zbox-settings.sh",
      "scripts/zbox-shell.sh",
      "scripts/zbox-vmware.sh",
      "scripts/zbox-cleanup.sh"
    ]
  }

  provisioner "file" {
    source      = "files/zbox.omp.json"
    destination = "$HOME/.poshthemes/zbox.omp.json"
  }

  provisioner "file" {
    source      = "files/tmux.conf"
    destination = "$HOME/.tmux.conf"
  }

  post-processor "shell-local" {
    environment_vars = [
      "APPLIANCE_NAME=${var.vm_name}",
      "APPLIANCE_VERSION=${var.version}",
      "APPLIANCE_OVA=${var.vm_name}_${var.version}"
    ]
    inline = [
      "cd postprocess-ova-properties",
      "./add_ovf_properties.sh"
    ]
  }
}