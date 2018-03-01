#!/bin/bash -x

cat <<EOF | sudo tee /srv/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --listen-client-urls=https://${NODE_IP}:2379
    - --advertise-client-urls=https://${NODE_IP}:2379
    - --data-dir=/var/lib/etcd
    - --name=${NODE_NAME}
    - --listen-peer-urls=https://${NODE_IP}:2380
    - --initial-cluster-state=new
    - --initial-cluster=${NODE1_NAME}=https://${NODE1_IP}:2380,${NODE2_NAME}=https://${NODE2_IP}:2380,${NODE3_NAME}=https://${NODE3_IP}:2380
    - --initial-advertise-peer-urls=https://${NODE_IP}:2380
    - --cert-file=/certs/server.pem
    - --key-file=/certs/server-key.pem
    - --client-cert-auth
    - --trusted-ca-file=/certs/ca.pem
    - --peer-cert-file=/certs/peer.pem
    - --peer-key-file=/certs/peer-key.pem
    - --peer-client-cert-auth
    - --peer-trusted-ca-file=/certs/ca.pem
    image: gcr.io/google_containers/etcd-amd64:3.1.11
    name: etcd
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd
    - mountPath: /certs
      name: certs
  hostNetwork: true
  volumes:
  - hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd
  - hostPath:
      path: /srv/kubernetes/pki/etcd
    name: certs

EOF

cat <<EOF | sudo tee /srv/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --apiserver-count=3
    - --advertise-address=${LB_IP}
    - --tls-ca-file=/srv/kubernetes/pki/ca.crt
    - --tls-cert-file=/srv/kubernetes/pki/server.crt
    - --tls-private-key-file=/srv/kubernetes/pki/server.key
    - --allow-privileged=true
    - --etcd-servers=https://${NODE1_IP}:2379,https://${NODE2_IP}:2379,https://${NODE3_IP}:2379
    - --etcd-cafile=/srv/kubernetes/pki/etcd/ca.pem
    - --etcd-certfile=/srv/kubernetes/pki/etcd/client.pem
    - --etcd-keyfile=/srv/kubernetes/pki/etcd/client-key.pem
    - --client-ca-file=/srv/kubernetes/pki/ca.crt
    - --service-cluster-ip-range=10.96.0.0/12
    - --insecure-port=0
    - --secure-port=6443
    - --enable-bootstrap-token-auth=true
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-username-headers=X-Remote-User
    - --requestheader-group-headers=X-Remote-Group
    - --logtostderr=true
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --admission-control=AlwaysPullImages,Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,NodeRestriction,ResourceQuota
    - --authorization-mode=Node,RBAC
    - --anonymous-auth=false
    - --kubelet-certificate-authority=/srv/kubernetes/pki/ca.crt
    - --kubelet-client-certificate=/srv/kubernetes/pki/node.crt
    - --kubelet-client-key=/srv/kubernetes/pki/node.key
    - --requestheader-client-ca-file=/srv/kubernetes/pki/ca.crt
    - --proxy-client-cert-file=/srv/kubernetes/pki/client.crt
    - --proxy-client-key-file=/srv/kubernetes/pki/client.key
    - --service-account-key-file=/srv/kubernetes/pki/sa.pub
    image: gcr.io/google_containers/kube-apiserver-amd64:v1.9.3
    name: kube-apiserver
    resources:
      requests:
        cpu: 250m
    volumeMounts:
    - mountPath: /etc/pki
      name: ca-certs-etc-pki
      readOnly: true
    - mountPath: /srv/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /srv/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/pki
      type: DirectoryOrCreate
    name: ca-certs-etc-pki

EOF

cat <<EOF | sudo tee /srv/kubernetes/manifests/kube-controllermanager.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-controller-manager
    tier: control-plane
  name: kube-controller-manager
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-controller-manager
    - --controllers=*,bootstrapsigner,tokencleaner
    - --root-ca-file=/srv/kubernetes/pki/ca.crt
    - --cluster-signing-cert-file=/srv/kubernetes/pki/ca.crt
    - --address=127.0.0.1
    - --kubeconfig=/srv/kubernetes/controller-manager.conf
    - --use-service-account-credentials=true
    - --service-account-private-key-file=/srv/kubernetes/pki/sa.key
    - --cluster-signing-key-file=/srv/kubernetes/pki/ca.key
    - --leader-elect=true
    image: gcr.io/google_containers/kube-controller-manager-amd64:v1.9.3
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: kube-controller-manager
    resources:
      requests:
        cpu: 200m
    volumeMounts:
    - mountPath: /srv/kubernetes/controller-manager.conf
      name: kubeconfig
      readOnly: true
    - mountPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      name: flexvolume-dir
    - mountPath: /etc/pki
      name: ca-certs-etc-pki
      readOnly: true
    - mountPath: /srv/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /srv/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /srv/kubernetes/controller-manager.conf
      type: FileOrCreate
    name: kubeconfig
  - hostPath:
      path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      type: DirectoryOrCreate
    name: flexvolume-dir
  - hostPath:
      path: /etc/pki
      type: DirectoryOrCreate
    name: ca-certs-etc-pki

EOF

cat <<EOF | sudo tee /srv/kubernetes/manifests/kube-scheduler.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --address=127.0.0.1
    - --leader-elect=true
    - --kubeconfig=/srv/kubernetes/scheduler.conf
    image: gcr.io/google_containers/kube-scheduler-amd64:v1.9.3
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10251
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: kube-scheduler
    resources:
      requests:
        cpu: 100m
    volumeMounts:
    - mountPath: /srv/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /srv/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig

EOF
