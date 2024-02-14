!#/bin/bash

### install Kubectl 
sudo curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.5/2024-01-04/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mkdir -p $HOME/bin  
sudo cp ./kubectl $HOME/bin/kubectl 
sudo export PATH=$HOME/bin:$PATH
sudo echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
kubectl version --client



## install AWS Console 

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip -u awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
which aws
ls -l /usr/local/bin/aws
aws --version

##################################### AWS configuration 
export AWS_AID=AKIAVNEMEULAQJOIDKHJ
export AWS_AKEY=v1szXfdaIyrbHkpxPMr4C6S+jXboc1jwoTjSXMeG
export AWS_AR=us-west-2

aws configure

## verifi user identy 
aws sts get-caller-identity

#################################### Install EKS 
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
sudo curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
sudo tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp 
sudo rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin


################################### Install Docker ans run eksctl in docker 
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker 
sudo systemctl start docker

## run in docker 
docker run --rm -it public.ecr.aws/eksctl/eksctl version





