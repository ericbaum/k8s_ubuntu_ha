#!/bin/bash -x

sudo openssl genrsa -out ${CA_DIR}/sa.key 2048

sudo openssl rsa -in sa.key -pubout -out sa.pub
