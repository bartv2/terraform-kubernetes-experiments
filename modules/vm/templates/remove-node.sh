#!/bin/bash

set -e

NODE_NAME=${1:-`hostname`}

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl drain $NODE_NAME --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node $NODE_NAME

# having param $1 set, implies that it's a worker node
if [ -v 1 ]; then exit 0 ; fi

ETCD_COUNT=$(etcdctl --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt member list  | wc -l)

# check for last controlplane node
if [ $ETCD_COUNT -eq 1 ]; then exit 0 ; fi

ETCD_ID=$(etcdctl --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint status  | awk -F, '{print $2}')

etcdctl --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt member remove $ETCD_ID
