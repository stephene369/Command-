#!/bin/bash

# Function to print a message in blue
print_blue() {
  echo -e "\e[34m$1\e[0m"
}

# Function to print a message in green
print_green() {
  echo -e "\e[32m$1\e[0m"
}

# Prompt for confirmation to execute the major step
confirm_step() {
  print_blue "$1"
  read -p "Would you like to continue with this step? (yes/no): " choice
  case "$choice" in
    yes|Yes|YES ) echo "Continuing...";;
    no|No|NO ) echo "Cancellation."; exit 1;;
    * ) echo "Please answer with 'yes' or 'no'."; confirm_step "$1";;
  esac
}

# Start of the step: Enable iptables Bridged Traffic on all nodes
confirm_step "Start of the step: Enable iptables Bridged Traffic on all nodes"
print_blue "Start of the step: Enable iptables Bridged Traffic on all nodes"

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

print_green "Step completed: Enable iptables Bridged Traffic on all nodes"

# Prompt for confirmation before executing the next major step
confirm_step "Step completed: Enable iptables Bridged Traffic on all nodes"

# Start of the step: Disable swap on all the Nodes
confirm_step "Start of the step: Disable swap on all the Nodes"
print_blue "Start of the step: Disable swap on all the Nodes"

sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

print_green "Step completed: Disable swap on all the Nodes"

# Prompt for confirmation before executing the next major step
confirm_step "Step completed: Disable swap on all the Nodes"

# Start of the step: Install Docker
confirm_step "Start of the step: Install Docker"
print_blue "Start of the step: Install Docker"

# Add Docker repository to Apt sources
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo systemctl start docker
sudo systemctl enable docker

print_green "Step completed: Install Docker"

# Prompt for confirmation before executing the next major step
confirm_step "Step completed: Install Docker"

# Start of the step: Install Kubernetes
confirm_step "Start of the step: Install Kubernetes"
print_blue "Start of the step: Install Kubernetes"

# Install dependency packages
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download and add GPG key
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

# Add the Kubernetes APT repository to your system
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package listings
sudo apt-get update -y

# Install Kubernetes packages
sudo apt-get install -y kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00

# Turn off automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

# Verification
kubeadm version

# Add the node IP to KUBELET_EXTRA_ARGS
sudo apt-get install -y jq
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

print_green "Step completed: Install Kubernetes"

# Prompt for confirmation before executing the next major step
confirm_step "Step completed: Install Kubernetes"

# Start of the step: Initialize the Kubernetes cluster
confirm_step "Start of the step: Initialize the Kubernetes cluster"
print_blue "Start of the step: Initialize the Kubernetes cluster"

# Install containerd
sudo apt-get update 
sudo apt-get install -y containerd

# Start containerd
sudo systemctl start containerd
sudo systemctl enable containerd

# Check if installed
sudo ls /var/run/containerd/containerd.sock

# On the Kubernetes master node, initialize the cluster
confirm_step "Would you like to continue with Kubernetes cluster initialization? (yes/no)"
print_blue "Would you like to continue with Kubernetes cluster initialization? (yes/no)"
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.24.0

# Set kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

print_green "Step completed: Initialize the Kubernetes cluster"

# Start of the step: Initialize Kubeadm on the master node to set up the control plane, Private IP mode
confirm_step "Start of the step: Initialize Kubeadm on the master node to set up the control plane, Private IP mode"
print_blue "Start of the step: Initialize Kubeadm on the master node to set up the control plane, Private IP mode"

# Get hostname
# Set pod CIDR
# Get private IP address
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
IPADDR=$(ip addr show | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -n 1)

# Print variables
echo "IPADDR=$IPADDR"
echo "NODENAME=$NODENAME"
echo "POD_CIDR=$POD_CIDR"

## Setup
sudo kubeadm init --control-plane-endpoint=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap

### To start using Cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## get Kube config
echo "Kube configuration : "
kubectl get po -n kube-system

# verify all the cluster component health statuses
kubectl get --raw='/readyz?verbose'

# get cluster infos
kubectl cluster-info 

print_green "Step completed: Initialize Kubeadm on the master node to set up the control plane, Private IP mode"

# Start of the step: Install Calico Network Plugin for Pod Networking
confirm_step "Start of the step: Install Calico Network Plugin for Pod Networking"
print_blue "Start of the step: Install Calico Network Plugin for Pod Networking"

## install CALICO network plugin
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml

print_green "Step completed: Install Calico Network Plugin for Pod Networking"

## Setup Kubernetes Metrics Server

# install the service : 
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# node and pod metrics 
kubectl top nodes

# pod CPU and memory metrics 
kubectl top pod -n kube-system

