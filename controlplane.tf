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
  cluster_endpoint_ip        = module.control_plane.ip_address[0]
  cluster_endpoint_with_user = "${var.ssh_admin}@${local.cluster_endpoint}"
  kubeadm_token_id           = substr(random_password.kubeadm_token.result, 0, 6)
  kubeadm_token              = join(".", [local.kubeadm_token_id, substr(random_password.kubeadm_token.result, 6, 16)])
  kubeadm_certificate_key    = random_id.kubeadm_certificate_key.hex
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

  runcmd = [
    "install-kubeadm.sh ${local.cluster_endpoint}:6443 ${local.kubeadm_token} --certificate-key ${local.kubeadm_certificate_key} --control-plane --discovery-token-unsafe-skip-ca-verification"
  ]
}

resource "ssh_resource" "control_plane_certs" {
  host        = local.cluster_endpoint_ip
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  timeout     = "1m"

  triggers = {
    count_changes = length(local.controleplane_ips)
    workers = var.worker_count
  }
  commands = [
    "sudo kubeadm init phase upload-certs --upload-certs --certificate-key ${local.kubeadm_certificate_key}",
    "sudo kubeadm token create ${local.kubeadm_token} || true",
  ]
}

resource "ssh_resource" "control_plane_destroy" {
  count       = length(local.controleplane_ips)
  host        = module.control_plane.ip_address[count.index]
  user        = var.ssh_admin
  private_key = var.ssh_private_key
  when        = "destroy"
  timeout     = "30s"

  commands = [
    "sudo /usr/local/bin/remove-node.sh"
  ]
}

output "control_plane" {
  value = module.control_plane
}
