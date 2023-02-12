#!/bin/bash

Status: WIP (not working)

# Add the Kubernetes nodes to /etc/hosts
cat << EOF | sudo tee -a /etc/hosts

# Kubernetes Lab
192.168.124.100 control-plane-0 control-plane-0.aperture.lab
192.168.124.110 worker-node-0 worker-node-0.aperture.lab
192.168.124.111 worker-node-1 worker-node-1.aperture.lab
EOF

# Disable Swap
swapoff -a 
sed -i -e '/swap/d' /etc/fstab 

# Configure System for Kubernetes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Update Firewall
sudo firewall-cmd --zone=public --add-service=kube-apiserver --permanent
sudo firewall-cmd --zone=public --add-service=etcd-client --permanent
sudo firewall-cmd --zone=public --add-service=etcd-server --permanent
# kubelet API
sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent
# kube-scheduler
sudo firewall-cmd --zone=public --add-port=10251/tcp --permanent
# kube-controller-manager
sudo firewall-cmd --zone=public --add-port=10252/tcp --permanent
# NodePort Services
sudo firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent
# apply changes
sudo firewall-cmd --reload

# Disable SELinux (not really sure why, but...)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


# Install Container Runtime (CRI-O)
OS=CentOS_8
VERSION=1.26
rm /etc/yum.repos.d/devel*
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
yum -y install cri-o
sudo systemctl enable --now cri-o
sudo systemctl enable crio.service --now

# Install Kube* (kubelet kubeadm kubectl
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

case `uname -n` in 
  control-plane-0.aperture.lab)
    sudo kubeadm init --pod-network-cidr=172.16.0.0/16
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ;;
esac


# Create Cluster Kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
case `uname -n` in 
  control-plane-0.aperture.lab)
    kubectl label node worker-node-0.aperture.lab node-role.kubernetes.io/worker="" 
    kubectl label node worker-node-1.aperture.lab node-role.kubernetes.io/worker="" 
    # CNI (Weaveworks needs additional ports)
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
    kubectl label node control-plane-0.aperture.lab weave=yes
    firewall-cmd --zone=public --add-port=6783/tcp --permanent
    firewall-cmd --zone=public --add-port=6783/udp --permanent
    firewall-cmd --zone=public --add-port=6784/udp --permanent
    firewall-cmd --reload

    # Kubernetes Dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

    # Install Metrics
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
    kubectl get apiservice v1beta1.metrics.k8s.io -o json | jq '.status'
    firewall-cmd --zone=public --add-port=6781/tcp --permanent
    firewall-cmd --zone=public --add-port=6782/tcp --permanent
    firewall-cmd --reload
  ;;
esac


