#!/bin/bash

set -e

sudo apt-mark hold kubelet kubeadm kubectl

#sudo systemctl restart systemd-networkd.service
#sudo systemctl reload systemd-networkd.service
#sudo systemctl stop systemd-resolved.service
#sudo systemctl disable systemd-resolved.service

sudo modprobe br_netfilter
sudo sysctl net.ipv4.ip_forward=1

#sudo kubeadm init --control-plane-endpoint=cluster-endpoint.k8s.lab
