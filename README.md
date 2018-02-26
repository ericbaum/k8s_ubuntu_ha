# K8s HA on Ubuntu


Repository with instructions and scripts to initialize a HA Kubernetes cluster

The steps presented below will lead to a kubernetes cluster installation with controller HA

All instructions are supposed to be run over Ubuntu 16.04

The expected results of this instructions are:

 * a kubernetes cluster running on High Availability
 *

## Install Docker

Run the docker installer script:

```bash
$ ./scripts/install_docker.sh
```

## Nodes initial configuration

On all nodes, create the following environment variables and folders:

```bash
$ export NODE_NAME=
$ export NODE_IP=
$ export LB_IP=
$ export INTERNAL_IP=10.96.0.1
$ export CA_DIR=/srv/kubernetes/pki
$ sudo mkdir -p /srv/kubernetes/manifests
$ sudo mkdir -p ${CA_DIR} 
```

## Generate Keys and Certificates

Run the commands to generate the CA and API certificates on one of the master nodes

### CA Certificate:

```bash
$ ./scripts/generate_ca.sh
```

### API Server Certificate:

```bash
$ ./scripts/generate_api_server_key.sh
```

### Service Account key:

```bash
$ ./scripts/generate_sa_key.sh
```

### Client certificate:

```bash
$ ./scripts/generate_client_key.sh
```

After generating the certificates, copy API, CA, Client and SA Certificates to all cluster nodes:

Copy the files from the master node

```bash
$ sudo scp -r ${CA_DIR} NODE_IP:${CA_DIR}
```

### Generate Kubelet Access Keys

On every node it is necessary to generate the node access key by running the following command and substituting the node ip with the proper value:

```bash
$ ./scripts/generate_node_key.sh
```
 
## Install Kubernetes Services

Run the kubernetes services install script on every node

```bash
$ ./scripts/install_kube_services.sh
```

## Configure kubelet service

Copy the configuration file to the kubelet service configuration directory

```bash
$ sudo mkdir -p /etc/systemd/system/kubelet.service.d/
$ sudo cp config_files/10-kubelet.conf /etc/systemd/system/kubelet.service.d/
$ sudo systemctl daemon-reload
```

## Create cluster access configuration files

Run the following commands on every node

```bash
$ ./scripts/configure_admin_access.sh
$ ./scripts/configure_kubelet_access.sh
$ ./scripts/configure_controller_manager_access.sh
$ ./scripts/configure_scheduler_access.sh
```

## Kubernetes controller services manifests

Now it is necessary to add the kubernetes controller service manifests to every node available

First, create the following folders on every master node of the cluster:

```bash
$ sudo mkdir -p /var/lib/etcd
$ sudo mkdir -p /etc/pki
$ sudo mkdir -p /etc/ssl/certs
```

To do so, edit the manifest files on the manifests folders with information
adequate to each of the nodes and copy all of them to the folder '/srv/kubernetes/manifests' 

## Restart the kubelet process

Restart the kubelet process

```bash
$ sudo systemctl enable kubelet
$ sudo systemctl restart kubelet
```



* TODO:
  * etcd tls
  * improve manifest copy
  * api server liveness probe failing
