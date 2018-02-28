#!/bin/bash -x

cat <<EOF | sudo tee ${CA_DIR}/tmp.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out ${CA_DIR}/tmp.key 2048

sudo openssl req -new -key ${CA_DIR}/tmp.key -subj "/CN=kubernetes-admin/O=system:masters" -out ${CA_DIR}/tmp.csr -config ${CA_DIR}/tmp.cnf

sudo openssl x509 -req -in ${CA_DIR}/tmp.csr -CA ${CA_DIR}/ca.crt -CAkey ${CA_DIR}/ca.key -CAcreateserial -out ${CA_DIR}/tmp.crt -days 10000 -extensions v3_req -extfile ${CA_DIR}/tmp.cnf

cat <<EOF | sudo tee /srv/kubernetes/admin.conf
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: $(cat ${CA_DIR}/ca.crt | base64 | tr -d '\n')
    server: https://${LB_IP}:6443
users:
- name: kubernetes-admin
  user:
    client-certificate-data: $(cat ${CA_DIR}/tmp.crt | base64 | tr -d '\n')
    client-key-data: $(cat ${CA_DIR}/tmp.key | base64 | tr -d '\n')
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
EOF

sudo rm ${CA_DIR}/tmp*
