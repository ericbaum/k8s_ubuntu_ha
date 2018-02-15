#!/bin/bash -x

export CA_DIR=/srv/pki/
sudo mkdir -p ${CA_DIR}
sudo openssl genrsa -out ${CA_DIR}/ca.key 2048
sudo openssl req -x509 -new -nodes -key ${CA_DIR}/ca.key -subj "/CN=kube-system" -days 10000 -out ${CA_DIR}/ca.crt
