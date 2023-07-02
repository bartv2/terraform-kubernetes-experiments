terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
  }
}
