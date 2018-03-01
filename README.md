# K8s HA on Ubuntu


Repository with instructions and scripts to initialize a HA Kubernetes cluster

The steps presented below will lead to a kubernetes cluster installation with controller HA behind a Load Balancer

All instructions are supposed to be run over Ubuntu 16.04

The expected results of this instructions are:

 * a kubernetes cluster running on High Availability
 * Kube Version 1.9.3

## Install Docker

Run the docker installer script on all nodes:

```bash
./scripts/install_docker.sh
```

## Nodes initial configuration

On all nodes, create the following environment variables and folders:

```bash
export NODE_NAME=
export NODE_IP=
export LB_IP=
export INTERNAL_IP=10.96.0.1
export CA_DIR=/srv/kubernetes/pki
sudo mkdir -p /srv/kubernetes/manifests
sudo mkdir -p ${CA_DIR} 
```

## Generate Keys and Certificates for Kubernetes

Run the commands to generate the CA and API certificates on one of the master nodes

### CA, API Server, Service Account and Client Certificats:

```bash
./scripts/generate_kubernetes_certificates.sh
```

After generating the certificates, copy API, CA, Client and SA Certificates to all cluster nodes:

Copy the files from the master node

```bash
sudo scp -r ${CA_DIR} NODE_IP:${CA_DIR}
```

### Generate Kubelet Access Keys

On every node it is necessary to generate the node access key by running the following command and substituting the node ip with the proper value:

```bash
./scripts/generate_node_key.sh
```
 
## Generate Keys and Certificates for Etcd

On an initial node, run the following script:

```bash
./scripts/generate_etcd_certificates.sh
```

Copy the files 'ca.pem', 'ca-key.pem', 'client.pem', 'client-key.pem' and 'ca-config.json' that were generated to the ${CA_DIR}/etcd of all other nodes that will run etcd.

After copying the files, run the following script on each of the nodes:

```bash
./scripts/generate_etcd_local.sh
```


## Install Kubernetes Services

Run the kubernetes services install script on every node

```bash
./scripts/install_kube_services.sh
```

## Configure kubelet service

Copy the configuration file to the kubelet service configuration directory

```bash
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
sudo cp config_files/10-kubelet.conf /etc/systemd/system/kubelet.service.d/
sudo systemctl daemon-reload
```

## Create cluster access configuration files

Run the following commands on every node

```bash
./scripts/configure_services_access.sh
```

## Kubernetes controller services manifests

Now it is necessary to add the kubernetes controller service manifests to every node available

First, create the following folders on every master node of the cluster:

```bash
sudo mkdir -p /var/lib/etcd
sudo mkdir -p /etc/pki
sudo mkdir -p /etc/ssl/certs
```

Now setup the environment variables equally on all nodes and run the following script to setup the manifests for every service

```bash
export NODE1_NAME=
export NODE1_IP=
export NODE2_NAME=
export NODE2IP=
export NODE3_NAME=
export NODE3_IP=

./scripts/write_manifests.sh
```

## Restart the kubelet process

Restart the kubelet process

```bash
sudo systemctl enable kubelet
sudo systemctl restart kubelet
```

## Accessing the cluster with the kubectl client

To access the cluster using the kubectl cluster, execute the following commands:

```bash
mkdir -p ~/.kube
sudo cp /srv/kubernetes/admin.conf ~/.kube/config
```

Then run any kubernetes command using the kubectl cli client to verify that it is working

## Set nodes master role label


For each of the nodes, run:
```bash
kubectl patch node ${NODE_NAME} -p '{"metadata": {"labels": {"node-role.kubernetes.io/master": ""}}}'
```
## Upload the configuration file to the cluster

```bash
kubectl create -n kube-system configmap kubeadm-config --from-file=MasterConfiguration=/srv/kubernetes/admin.conf
```
## Install the addon services

### Kube-Proxy

With the cluster up and running it is necessary to start the kube-proxy service to allow the usage of ClusterIP services

To do so, edit the manifest, setting the correct load balancer IP and execute the following command:

```bash
kubectl apply -f ./addons/kube-proxy.yaml
```

### Kube-DNS
```bash
kubectl apply -f ./addons/kube-dns.yaml
```

## Instantiate a CNI network module

```bash
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

* TODO:
  * api server liveness probe failing
  * etcd liveness probe
  * solve kubectl logs and exec problem with certificates
