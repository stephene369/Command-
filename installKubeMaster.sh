#!/bin/bash

############### Enable iptables Brifged Trafic an all nodes 
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


###############
############### Disable swap on all the Nodes
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true


################################### INSTALL DOCKER ############################

## Add repository : 
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker


############################### INSTALL KUBERNATES ###############################333

# Install dependency packages:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl


### Download and add GPG key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

### Add the Kubernetes APT repository to your system.
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package listings:
sudo apt-get update -y

### You can use the following commands to find the latest versions.
sudo apt update
apt-cache madison kubeadm | tac

# Install Kubernetes packages. Note: use the following command "sudo kill -9 $( sudo lsof /var/lib/dpkg/lock-frontend | awk '{ print $2 }' | tail -1 )" if you receive a "E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?" message.
sudo apt-get install -y kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00

# Turn off automatic updates:
sudo apt-mark hold kubelet kubeadm kubectl

## verification 
kubeadm version 

### Add the node IP to KUBELET_EXTRA_ARGS.
sudo apt-get install -y jq
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF






######################################## BOOSTRAP THE CLUSTER 


# install containerd
sudo apt-get update 
sudo apt-get install -y containerd

## start containerd 
sudo systemctl start containerd
sudo systemctl enable containerd

### Check if installed : 
sudo ls /var/run/containerd/containerd.sock

# On the Kube master node, initialize the cluster:
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.24.0

# Set kubectl access:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config





################## Initialize Kubeadm 
################## On Master Node To Setup 
################## Control Plane , @@@@@@@@@@@@@@@@@@@ Private Ip mode


# Get hostname 
# Set pod CIDR
# Get private IP address 

NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
IPADDR=$(ip addr show | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
#IPADDR=$(curl ifconfig.me && echo "") # For Public IP

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

# get cluster infos :
kubectl cluster-info 



######################################## Install Calico Network Plugin for Pod Networking

## install CALICO network plugin 
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O

kubectl create -f custom-resources.yaml








