#!/bin/bash

set -e

apt-mark hold kubelet kubeadm kubectl

modprobe br_netfilter
sysctl --system

# don't rerun install when not needed
[ -e /etc/kubernetes/admin.conf ] && exit 0

ENDPOINT=$1
TOKEN=$2
CERT_KEY=$3
OTHER_JOIN_ARGS=${*:4}

INIT=0
if [ `hostname` = 'controlplane-01' ]; then INIT=1 ; fi

if [ $INIT -eq 1 ]; then
  kubeadm init --control-plane-endpoint=$ENDPOINT --upload-certs --certificate-key $CERT_KEY --token $TOKEN
else
  kubeadm join $ENDPOINT --certificate-key $CERT_KEY --token $TOKEN $OTHER_JOIN_ARGS
fi
