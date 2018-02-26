#!/bin/bash -x

sudo openssl genrsa -out ${CA_DIR}/sa.key 2048

sudo openssl rsa -in ${CA_DIR}/sa.key -pubout -out ${CA_DIR}/sa.pub
