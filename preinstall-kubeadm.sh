#!/bin/bash

set -e

# don't rerun install when not needed
[ -e /etc/apt/keyrings/kubernetes-archive-keyring.gpg ] && exit 0

sudo apt-get install -y auto-apt-proxy

sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


sudo mkdir /etc/systemd/network/10-netplan-ens3.network.d/
sudo tee /etc/systemd/network/10-netplan-ens3.network.d/override.conf <<EOT
[DHCPv4]
UseDomains=true

[DHCPv6]
UseDomains=true

[IPv6AcceptRA]
UseDomains=true
EOT
#sudo systemctl restart systemd-networkd.service
sudo systemctl reload systemd-networkd.service
sudo systemctl stop systemd-resolved.service
sudo systemctl disable systemd-resolved.service

sudo apt-get install -y containerd containernetworking-plugins
echo "br_netfilter" | sudo tee  /etc/modules-load.d/kubeadm.conf
echo "net.ipv4.ip_forward = 1" | sudo tee  /etc/sysctl.d/50-kubeadm.conf
sudo modprobe br_netfilter
sudo sysctl net.ipv4.ip_forward=1

#sudo kubeadm init --control-plane-endpoint=cluster-endpoint.k8s.local
