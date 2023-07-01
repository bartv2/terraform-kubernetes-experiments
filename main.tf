provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "cluster" {
  name = "default"
  type = "dir"
  path = var.pool_path
}

resource "libvirt_network" "default" {
  name      = "default"
  addresses = var.networks
}

module "control_plane" {
  source  = "MonolithProjects/vm/libvirt"
  version = "1.10.0"

  autostart          = false
  vm_hostname_prefix = "control_plane-"
  vm_count           = 1
  memory             = "2048"
  vcpu               = 1
  system_volume      = 10

  time_zone = "CET"

  os_img_url = var.os_img_url
  pool       = libvirt_pool.cluster.name

  dhcp   = true
  bridge = libvirt_network.default.bridge

  ssh_admin       = var.ssh_admin
  ssh_private_key = var.ssh_private_key
  ssh_keys = [
    file("${var.ssh_private_key}.pub"),
  ]
}

output "outputs" {
  value = module.control_plane
}
