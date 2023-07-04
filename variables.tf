variable "os_img_url" {
  description = "URL to the OS image"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

variable "pool_path" {
  description = "Pool path to store volumes"
  type        = string
  # /var/lib/libvirt/images/
  default = "/home/cluster_storage"
}

variable "networks" {
  description = "List of network ranges"
  type        = list(string)
  default     = ["10.17.3.0/24"]
}

variable "ssh_admin" {
  description = "Admin user with ssh access"
  type        = string
  default     = "admin"
}

variable "ssh_private_key" {
  description = "Private key for SSH"
  type        = string
  # "~/.ssh/id_ed25519"
  default = "id_ed25519"
}

variable "ssh_keys" {
  description = "List of public ssh keys"
  type        = list(string)
  default     = []
}

variable "controlplane_count" {
  description = "Count of controle-plane vms to make"
  type        = number
  default     = 1
}

variable "http_proxy" {
  description = "apt http_proxy"
  type        = string
  default     = ""
}
