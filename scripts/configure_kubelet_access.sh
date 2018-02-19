#!/bin/bash -x

cat <<EOF | sudo tee /srv/kubernetes/kubelet.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority: /srv/pki/ca.crt
    server: http://127.0.0.1:6444
users:
- name: system:node:${NODE_NAME}
  user:
    client-certificate: /srv/pki/node.crt
    client-key: /srv/pki/node.key
contexts:
- context:
    cluster: kubernetes
    user: system:node:${NODE_NAME}
  name: kubelet-context
current-context: kubelet-context
EOF
