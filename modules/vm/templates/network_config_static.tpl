version: 2
ethernets:
  ${nic}:
    dhcp4: no
    addresses: [${ip_address}/24]
    gateway4: ${ip_gateway}
    nameservers:
       search: [ k8s.lab ]
       addresses:
        - ${ip_nameserver}
