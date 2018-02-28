#!/bin/bash -x

cd ${CA_DIR}

cat <<EOF | sudo tee node-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out node.key 2048
sudo openssl req -new -key node.key -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -out node.csr -config node-openssl.cnf
sudo openssl x509 -req -in node.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out node.crt -days 10000 -extensions v3_req -extfile node-openssl.cnf
sudo openssl x509 -noout -text -in node.crt

cd -
