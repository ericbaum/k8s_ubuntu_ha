#!/bin/bash -x

cd ${CA_DIR}

cat <<EOF | sudo tee tmp.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out tmp.key 2048

sudo openssl req -new -key tmp.key -subj "/CN=kubernetes-admin/O=system:masters" -out tmp.csr -config tmp.cnf

sudo openssl x509 -req -in tmp.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tmp.crt -days 10000 -extensions v3_req -extfile tmp.cnf

cat <<EOF | sudo tee /srv/kubernetes/admin.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: $(cat ca.crt | base64 | tr -d '\n')
    server: https://${LB_IP}:6443
users:
- name: kubernetes-admin
  user:
    client-certificate-data: $(cat tmp.crt | base64 | tr -d '\n')
    client-key-data: $(cat tmp.key | base64 | tr -d '\n')
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
EOF

sudo rm tmp*

cat <<EOF | sudo tee tmp.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out tmp.key 2048

sudo openssl req -new -key tmp.key -subj "/CN=system:node:${NODE_NAME}/O=system:nodes" -out tmp.csr -config tmp.cnf

sudo openssl x509 -req -in tmp.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tmp.crt -days 10000 -extensions v3_req -extfile tmp.cnf

cat <<EOF | sudo tee /srv/kubernetes/kubelet.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: $(cat ca.crt | base64 | tr -d '\n')
    server: https://${LB_IP}:6443
users:
- name: system:node:${NODE_NAME}
  user:
    client-certificate-data: $(cat tmp.crt | base64 | tr -d '\n')
    client-key-data: $(cat tmp.key | base64 | tr -d '\n')
contexts:
- context:
    cluster: kubernetes
    user: system:node:${NODE_NAME}
  name: node@kubernetes
current-context: node@kubernetes
EOF

sudo rm tmp*

cat <<EOF | sudo tee tmp.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out tmp.key 2048

sudo openssl req -new -key tmp.key -subj "/CN=system:kube-controller-manager" -out tmp.csr -config tmp.cnf

sudo openssl x509 -req -in tmp.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tmp.crt -days 10000 -extensions v3_req -extfile tmp.cnf

cat <<EOF | sudo tee /srv/kubernetes/controller-manager.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: $(cat ca.crt | base64 | tr -d '\n')
    server: https://${LB_IP}:6443
users:
- name: system:kube-controller-manager
  user:
    client-certificate-data: $(cat tmp.crt | base64 | tr -d '\n')
    client-key-data: $(cat tmp.key | base64 | tr -d '\n')
contexts:
- context:
    cluster: kubernetes
    user: system:kube-controller-manager
  name: system:kube-controller-manager@kubernetes
current-context: system:kube-controller-manager@kubernetes
EOF

sudo rm tmp*

cat <<EOF | sudo tee tmp.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out tmp.key 2048

sudo openssl req -new -key tmp.key -subj "/CN=system:kube-scheduler" -out tmp.csr -config tmp.cnf

sudo openssl x509 -req -in tmp.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tmp.crt -days 10000 -extensions v3_req -extfile tmp.cnf

cat <<EOF | sudo tee /srv/kubernetes/scheduler.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: $(cat ca.crt | base64 | tr -d '\n')
    server: https://${LB_IP}:6443
users:
- name: system:kube-scheduler
  user:
    client-certificate-data: $(cat tmp.crt | base64 | tr -d '\n')
    client-key-data: $(cat tmp.key | base64 | tr -d '\n')
contexts:
- context:
    cluster: kubernetes
    user: system:kube-scheduler
  name: system:kube-scheduler@kubernetes
current-context: system:kube-scheduler@kubernetes
EOF

sudo rm tmp*

cd -
