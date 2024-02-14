!#/bin/bash

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
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin


################################### Install Docker ans run eksctl in docker 
sudo apt  install docker.io
sudo systemctl enable docker 
sudo systemctl start docker

## run in docker 
docker run --rm -it public.ecr.aws/eksctl/eksctl version





