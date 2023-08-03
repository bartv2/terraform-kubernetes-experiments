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

module "workers" {
  source = "./modules/vm"

  autostart          = false
  vm_hostname_prefix = "worker"
  vm_count           = var.worker_count
  memory             = "1024"
  vcpu               = 1
  system_volume      = 10

  time_zone = "CET"

  os_img_url = var.os_img_url
  pool       = libvirt_pool.cluster.name

  dhcp = true
#  vm_domain     = local.domainname
#  ip_address    = local.controleplane_ips
#  ip_gateway    = cidrhost(local.controleplane_network, 1)
#  ip_nameserver = cidrhost(local.controleplane_network, 1)

  bridge = libvirt_network.default.bridge

  http_proxy = var.http_proxy

  ssh_admin       = var.ssh_admin
  ssh_private_key = var.ssh_private_key
  ssh_keys = [
    file("${var.ssh_private_key}.pub"),
  ]

  runcmd = [
    "install-kubeadm.sh ${local.cluster_endpoint}:6443 ${local.kubeadm_token} --discovery-token-unsafe-skip-ca-verification"
  ]
}

resource "ssh_resource" "workers_destroy" {
  count       = var.worker_count
  host        = local.cluster_endpoint_ip
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  when        = "destroy"
  timeout     = "30s"

  commands = [
    "sudo /usr/local/bin/remove-node.sh ${module.workers.name[count.index]}"
  ]
}

resource "ssh_resource" "sample_work" {
  host        = local.cluster_endpoint_ip
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  timeout     = "11s"

  file {
    source      = "sample_work.yaml"
    destination = "/tmp/sample_work.yaml"
  }

  commands = [
    "sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /tmp/sample_work.yaml"
  ]
}

output "worker" {
  value = module.workers
}
output "run" {
  value = ssh_resource.sample_work.result
}
