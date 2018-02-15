#!/bin/bash -x

cat <<EOF | sudo tee /srv/kubernetes/controller-manager.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority: /srv/pki/ca.crt
    server: https://10.50.11.32:6443
users:
- name: system:kube-controller-manager
  user:
    client-certificate: /srv/pki/node.crt
    client-key: /srv/pki/node.key
contexts:
- context:
    cluster: kubernetes
    user: system:kube-controller-manager
  name: system:kube-controller-manager@kubernetes
current-context: system:kube-controller-manager@kubernetes
EOF
