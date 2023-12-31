#cloud-config

package_upgrade: false

apt:
%{ if http_proxy != "" }
  http_proxy: ${http_proxy}
  primary:
    - arches: [default]
      uri: 'http://deb.debian.org/debian'
  security:
    - arches: [default]
      uri: 'http://deb.debian.org/debian-security'
%{ endif }
  sources:
    kubernetes.list:
      source: deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] http://apt.kubernetes.io/ kubernetes-xenial main
    ${apt_sources}

packages:
  - iotop
  - qemu-guest-agent
  - kubelet
  - kubeadm
  - kubectl
  - containerd
  - containernetworking-plugins
  - etcd-client

runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, qemu-guest-agent ]
  - [ systemctl, restart, systemd-networkd ]
${runcmd}
  - [ systemctl, start, qemu-guest-agent ]

fqdn: ${hostname}

users:
  - name: ${ssh_admin}
    gecos: CI User
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    system: False
    ssh_authorized_keys: ${ssh_keys}
    shell: /bin/bash
%{ if local_admin != "" }
  - name: ${local_admin}
    gecos: Local admin (no SSH)
    lock-passwd: false
    sudo: ALL=(ALL) ALL
    passwd: ${local_admin_passwd}
    shell: /bin/bash
%{ endif }

write_files:
  - path: /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    content: !!binary |
        ${ indent(8, file("${path}/templates/kubernetes-archive-keyring.asc")) }
  - path: /etc/ssh/sshd_config
    content: |
        Port 22
        Protocol 2
        HostKey /etc/ssh/ssh_host_rsa_key
        HostKey /etc/ssh/ssh_host_dsa_key
        HostKey /etc/ssh/ssh_host_ecdsa_key
        HostKey /etc/ssh/ssh_host_ed25519_key
        SyslogFacility AUTH
        LogLevel INFO
        LoginGraceTime 120
        PermitRootLogin no
        StrictModes yes
        PubkeyAuthentication yes
        IgnoreRhosts yes
        HostbasedAuthentication no
        PermitEmptyPasswords no
        ChallengeResponseAuthentication no
        X11Forwarding yes
        X11DisplayOffset 10
        PrintMotd no
        PrintLastLog yes
        TCPKeepAlive yes
        AcceptEnv LANG LC_*
        Subsystem sftp /usr/lib/openssh/sftp-server
        UsePAM yes
        AllowUsers ${ssh_admin}
  - path: /etc/systemd/network/10-netplan-ens3.network.d/override.conf
    content: |
      [DHCPv4]
      UseDomains=true

      [DHCPv6]
      UseDomains=true

      [IPv6AcceptRA]
      UseDomains=true
  - path: /etc/modules-load.d/kubeadm.conf
    content: "br_netfilter"
  - path: /etc/sysctl.d/50-kubeadm.conf
    content: "net.ipv4.ip_forward = 1"
  - path: /etc/crictl.yaml
    content: |
      runtime-endpoint: unix:///var/run/containerd/containerd.sock
      image-endpoint: unix:///var/run/containerd/containerd.sock
  - path: /etc/containerd/config.toml
    content: |
        ${ indent(8, file("${path}/templates/containerd-config.toml")) }
  - path: /usr/local/bin/install-kubeadm.sh
    permissions: 0o755
    content: |
        ${ indent(8, file("${path}/templates/install-kubeadm.sh")) }
  - path: /usr/local/bin/remove-node.sh
    permissions: 0o755
    content: |
        ${ indent(8, file("${path}/templates/remove-node.sh")) }

growpart:
    mode: auto
    devices:
      - "/"

resize_rootfs: true

timezone: ${time_zone}
