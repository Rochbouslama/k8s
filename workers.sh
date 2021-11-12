#!/bin/bash

echo "==> Update and Upgrade"
sudo apt update
sudo apt -y upgrade

echo "----------------------------------"

echo "==> Install kubelet, kubeadm and kubectl"
echo "--> Add Kubernetes repository for Ubuntu 20.04"
sudo apt -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "--> Add Kubernetes repository for Ubuntu 20.04"
sudo apt update
sudo apt -y install vim git curl wget kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

kubectl version --client && kubeadm version

echo "--> Disable Swap"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

echo "--> Enable kernel modules"
sudo modprobe overlay
sudo modprobe br_netfilter

echo "--> Add some settings to sysctl"
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

echo "--> Reload sysctl"
sudo sysctl --system

echo "==> Installing Docker runtime"
echo "--> Add repo and Install packages"
sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli

echo "--> Create required directories"
sudo mkdir -p /etc/systemd/system/docker.service.d

echo "--> Create daemon json config file"
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo "--> Start and enable Services"
sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

sudo tee /etc/hosts <<EOF
192.168.1.30 master
192.168.1.23 worker1
192.168.1.42 worker2
192.168.1.32 worker3
EOF


sudo kubeadm join 192.168.1.30:6443 --token 1zhr6n.c874mikayysfdxkn --discovery-token-ca-cert-hash sha256:23f937ef3ec6dd553fe34eaaaeaf4768189223196be08b6077b344aece70bac5
