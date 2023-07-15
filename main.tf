provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "cluster" {
  name = "default"
  type = "dir"
  path = var.pool_path
}

resource "random_password" "kubeadm_token" {
  length  = 22
  special = false
  upper   = false
}

resource "random_id" "kubeadm_certificate_key" {
  byte_length = 32
}

locals {
  controleplane_network      = var.networks[0]
  controleplane_ips          = [for i in range(2, 2 + var.controlplane_count) : cidrhost(local.controleplane_network, i)]
  domainname                 = "k8s.lab"
  cluster_endpoint           = "cluster-endpoint.${local.domainname}"
  cluster_endpoint_with_user = "${var.ssh_admin}@${local.cluster_endpoint}"
  kubeadm_token_id           = substr(random_password.kubeadm_token.result, 0, 6)
  kubeadm_token              = join(".", [local.kubeadm_token_id, substr(random_password.kubeadm_token.result, 6, 16)])
  kubeadm_certificate_key    = random_id.kubeadm_certificate_key.hex
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

module "control_plane" {
  source = "./modules/vm"

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
  vm_domain     = local.domainname
  ip_address    = local.controleplane_ips
  ip_gateway    = cidrhost(local.controleplane_network, 1)
  ip_nameserver = cidrhost(local.controleplane_network, 1)

  bridge = libvirt_network.default.bridge

  http_proxy = var.http_proxy

  ssh_admin       = var.ssh_admin
  ssh_private_key = var.ssh_private_key
  ssh_keys = [
    file("${var.ssh_private_key}.pub"),
  ]
}
resource "ssh_resource" "control_plane_certs" {
  host        = module.control_plane.ip_address[0]
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  timeout     = "1m"

  triggers = {
    count_changes = length(local.controleplane_ips)
  }
  commands = [
    "sudo kubeadm init phase upload-certs --upload-certs --certificate-key ${local.kubeadm_certificate_key}",
    "sudo kubeadm token create ${local.kubeadm_token} || true",
  ]
}
resource "ssh_resource" "control_plane" {
  count       = length(local.controleplane_ips)
  host        = module.control_plane.ip_address[count.index]
  user        = var.ssh_admin
  private_key = var.ssh_private_key

  commands = [
    "sudo /usr/local/bin/install-kubeadm.sh cluster-endpoint.k8s.lab:6443 ${local.kubeadm_token} ${local.kubeadm_certificate_key} --control-plane --discovery-token-unsafe-skip-ca-verification"
  ]
}

resource "ssh_resource" "control_plane_destroy" {
  count       = length(local.controleplane_ips)
  host        = module.control_plane.ip_address[count.index]
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  when        = "destroy"
  timeout     = "30s"

  file {
    source      = "remove-node.sh"
    destination = "/tmp/remove-node.sh"
    permissions = "0700"
  }

  commands = [
    "sudo /tmp/remove-node.sh"
  ]
}

# kubeadm init phase upload-certs --upload-certs --certificate-key d9456efcc50c12d8f5fff93c097a16d2495fb5df9cb17cd2fd26f8022a926af4
# kubeadm token create qahkjs.ru8katsu52fep1ea

## kubectl cordon controlplane-02
# kubectl drain controlplane-02 --ignore-daemonsets
# kubectl delete node controlplane-02

# sudo etcdctl --endpoints=127.0.0.1:2379 --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint status
# sudo etcdctl --endpoints=cluster-endpoint.k8s.lab:2379 --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt member remove c7b9a74f4a348e3d

output "outputs" {
  value = module.control_plane
}
output "run" {
  value = ssh_resource.control_plane[*].result
}
