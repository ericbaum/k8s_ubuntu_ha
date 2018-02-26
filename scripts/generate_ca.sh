#!/bin/bash -x

sudo openssl genrsa -out ${CA_DIR}/ca.key 2048
sudo openssl req -x509 -new -nodes -key ${CA_DIR}/ca.key -subj "/CN=kubernetes" -days 10000 -out ${CA_DIR}/ca.crt
