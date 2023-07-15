#!/bin/bash

set -e

NODE_NAME=`hostname`

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl drain $NODE_NAME --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node $NODE_NAME

ETCD_ID=$(etcdctl --endpoints=127.0.0.1:2379 --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint status  | awk -F, '{print $2}')

etcdctl --endpoints=127.0.0.1:2379 --key /etc/kubernetes/pki/etcd/healthcheck-client.key --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt --cacert /etc/kubernetes/pki/etcd/ca.crt member remove $ETCD_ID
