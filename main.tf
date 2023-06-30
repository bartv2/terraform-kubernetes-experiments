terraform {
  required_version = ">= 0.13"
    required_providers {
      libvirt = {
        source  = "dmacvicar/libvirt"
        version = ">= 0.7.0"
      }
    }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "cluster" {
  name = "default"
  type = "dir"
  path = "/home/cluster_storage"
}

resource "libvirt_network" "default" {
  name = "default"
  addresses = ["10.17.3.0/24"]
}

module "vm" {
  source  = "MonolithProjects/vm/libvirt"
  version = "1.10.0"

  autostart = false
  vm_hostname_prefix = "server"
  vm_count    = 3
  memory      = "2048"
  pool = libvirt_pool.cluster.name
  vcpu        = 1
  system_volume = 10

  dhcp        = true

#  local_admin = "local-admin"
#  local_admin_passwd = "$6$rounds=4096$xxxxxxxxHASHEDxxxPASSWORD"

  ssh_admin   = "admin"
#  ssh_private_key = "~/.ssh/id_ed25519"
  ssh_private_key = "id_ed25519"
  ssh_keys    = [
#    file("~/.ssh/id_ed25519.pub"),
    file("id_ed25519.pub"),
    ]

  time_zone   = "CET"
#  https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2
  os_img_url  = "file://${path.cwd}/debian-11-genericcloud-amd64.qcow2"
}

output "outputs" {
  value = module.vm
}
