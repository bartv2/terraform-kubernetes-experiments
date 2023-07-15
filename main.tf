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
  domain    = local.domainname
  bridge    = "virbr0"
  dns {
    hosts {
      ip       = local.controleplane_ips[0]
      hostname = "cluster-endpoint"
    }
    dynamic "hosts" {
      for_each = local.controleplane_ips
      content {
        ip       = hosts.value
        hostname = format("controlplane-%02d", hosts.key + 1)
      }
    }
  }
}
