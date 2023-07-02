provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "cluster" {
  name = "default"
  type = "dir"
  path = var.pool_path
}

locals {
  controleplane_network = var.networks[0]
  controleplane_ips = [for i in range(2, 2+var.controlplane_count): cidrhost(local.controleplane_network, i)]
}

resource "libvirt_network" "default" {
  name      = "default"
  addresses = var.networks
  domain    = "k8s.local"
  bridge    = "virbr0"
  dns {
    hosts {
      ip       = local.controleplane_ips[0]
      hostname = "cluster-endpoint"
    }
  }
}

module "control_plane" {
  source  = "MonolithProjects/vm/libvirt"
  version = "1.10.0"

  autostart          = false
  vm_hostname_prefix = "controlplane-"
  vm_count           = length(local.controleplane_ips)
  memory             = "2048"
  vcpu               = 2
  system_volume      = 10

  time_zone = "CET"

  os_img_url = var.os_img_url
  pool       = libvirt_pool.cluster.name

#  dhcp = true
  ip_address  = local.controleplane_ips
  ip_gateway  = cidrhost(local.controleplane_network, 1)
  ip_nameserver = cidrhost(local.controleplane_network, 1)

  bridge = libvirt_network.default.bridge

  ssh_admin       = var.ssh_admin
  ssh_private_key = var.ssh_private_key
  ssh_keys = [
    file("${var.ssh_private_key}.pub"),
  ]
}

resource "ssh_resource" "control_plane" {
  host        = module.control_plane.ip_address[0]
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  timeout = "10m"

  file {
    source      = "preinstall-kubeadm.sh"
    destination = "/tmp/preinstall-kubeadm.sh"
    permissions = "0700"
  }

  file {
    #content     = "sudo kubeadm --token qjtm24.wnu9yb6ls0zl9zkx --discovery-token-ca-cert-hash --control-plane cluster-endpoint.k8s.local"
    content     = "sudo kubeadm init --control-plane-endpoint=cluster-endpoint.k8s.local"
    destination = "/tmp/install-kubeadm.sh"
    permissions = "0700"
  }

  commands = [
    "/tmp/preinstall-kubeadm.sh",
    "/tmp/install-kubeadm.sh"
  ]
}

# kubeadm init --control-plane-endpoint=cluster-endpoint --token [a-z0-9]{6}.[a-z0-9]{16}

output "outputs" {
  value = module.control_plane
}
#output "run" {
#  value = ssh_resource.control_plane.result
#}
