#!/bin/bash -x

sudo curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sudo curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo chmod +x /usr/local/bin/cfssl*

cd /srv/kubernetes/pki/etcd

# TODO: Find a way of setting the variables below:

cat <<EOF | sudo tee config.json
{
    "CN": "${NODE_NAME}",
    "hosts": [
        "${NODE_NAME}",
        "${NODE_IP}"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF

sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | sudo cfssljson -bare server
sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | sudo cfssljson -bare peer

cd -
