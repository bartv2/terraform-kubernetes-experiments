- install terraform (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- add packages: libvirt-daemon-system qemu-utils qemu-system-x86
- ssh-keygen -f id_ed25519 -t ed25519 -C terraform@main
- https://askubuntu.com/a/1293019 AppArmor preventing access to storage pool

run the command below to access the sample workload
``` bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl port-forward --address 0.0.0.0 svc/frontend 8080:80
```

``` bash
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
