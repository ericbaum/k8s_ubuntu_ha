#!/bin/bash -x

sudo curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sudo curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo chmod +x /usr/local/bin/cfssl*

sudo mkdir -p ${CA_DIR}/etcd

cd ${CA_DIR}/etcd

cat <<EOF | sudo tee ca-config.json
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat <<EOF | sudo tee ca-csr.json
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
EOF

sudo cfssl gencert -initca ca-csr.json | sudo cfssljson -bare ca -

cat <<EOF | sudo tee client.json
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF

sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | sudo cfssljson -bare client

cd -
