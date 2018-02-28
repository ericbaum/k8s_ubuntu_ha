#!/bin/bash -x

cd ${CA_DIR}

sudo openssl genrsa -out ca.key 2048
sudo openssl req -x509 -new -nodes -key ca.key -subj "/CN=kubernetes" -days 10000 -out ca.crt

cat <<EOF | sudo tee server-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${LB_IP}
IP.2 = ${INTERNAL_IP}
IP.3 = 127.0.0.1
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
EOF

sudo openssl genrsa -out server.key 2048
sudo openssl req -new -key server.key -subj "/CN=kube-apiserver" -out server.csr -config server-openssl.cnf
sudo openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 10000 -extensions v3_req -extfile server-openssl.cnf
sudo openssl x509 -noout -text -in server.crt

sudo openssl genrsa -out sa.key 2048
sudo openssl rsa -in sa.key -pubout -out sa.pub

cat <<EOF | sudo tee client-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out client.key 2048

sudo openssl req -new -key client.key -subj "/CN=client" -out client.csr -config client-openssl.cnf

sudo openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 10000 -extensions v3_req -extfile client-openssl.cnf

sudo openssl x509 -noout -text -in client.crt

cd -
