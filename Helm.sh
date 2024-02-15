!#/bin/bash 


### Make sure to have EKS ans kubectl install and running  
kubectl get svc

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

### init helm chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

sudo yum install openssl

## version 
helm version | cut -d + -f 1
