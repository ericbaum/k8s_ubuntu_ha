#!/bin/bash -x

cat <<EOF | sudo tee ${CA_DIR}/client-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

sudo openssl genrsa -out ${CA_DIR}/client.key 2048

sudo openssl req -new -key ${CA_DIR}/client.key -subj "/CN=client" -out ${CA_DIR}/client.csr -config ${CA_DIR}/client-openssl.cnf

sudo openssl x509 -req -in ${CA_DIR}/client.csr -CA ${CA_DIR}/ca.crt -CAkey ${CA_DIR}/ca.key -CAcreateserial -out ${CA_DIR}/client.crt -days 10000 -extensions v3_req -extfile ${CA_DIR}/client-openssl.cnf

sudo openssl x509 -noout -text -in ${CA_DIR}/client.crt
