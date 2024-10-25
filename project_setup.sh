export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
export MY_RESOURCE_GROUP_NAME="webops_temp"
export REGION="canadacentral"
export MY_AKS_CLUSTER_NAME="webopsAKSCluster"
export MY_PUBLIC_IP_NAME="webopsPublicIP"
export MY_DNS_LABEL="webopsdnslabel"
export MY_VNET_NAME="webopsVNet"
export MY_VNET_PREFIX="10.$NETWORK_PREFIX.0.0/16"
export MY_SN_NAME="webopsSN"
export MY_SN_PREFIX="10.$NETWORK_PREFIX.0.0/22"
export MY_WP_ADMIN_PW="g8tr_p#dw9RDo"
export MY_WP_ADMIN_USER="webops"
export FQDN="${MY_DNS_LABEL}.${REGION}.cloudapp.azure.com"
export MY_MYSQL_DB_NAME="webopsdb"
export MY_MYSQL_ADMIN_USERNAME="groupadmin"
export MY_MYSQL_ADMIN_PW="admin96705"
export MY_MYSQL_SN_NAME="myMySQLSN"
export MY_MYSQL_HOSTNAME="$MY_MYSQL_DB_NAME.mysql.database.azure.com"
export ACR_NAME="webopsacr"
export $MY_NAMESPACE="webops-ns"



az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

az network vnet create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --location $REGION \
    --name $MY_VNET_NAME \
    --address-prefix $MY_VNET_PREFIX \
    --subnet-name $MY_SN_NAME \
    --subnet-prefixes $MY_SN_PREFIX

az mysql flexible-server create \
    --admin-password $MY_MYSQL_ADMIN_PW \
    --admin-user $MY_MYSQL_ADMIN_USERNAME \
    --auto-scale-iops Disabled \
    --high-availability Disabled \
    --iops 500 \
    --location $REGION \
    --name $MY_MYSQL_DB_NAME \
    --database-name wordpress \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --sku-name Standard_B2s \
    --storage-auto-grow Disabled \
    --storage-size 20 \
    --subnet $MY_MYSQL_SN_NAME \
    --private-dns-zone $MY_DNS_LABEL.private.mysql.database.azure.com \
    --tier Burstable \
    --version 8.0.21 \
    --vnet $MY_VNET_NAME \
    --yes -o JSON

runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_DB_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done

az acr create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NAME --sku Basic

az acr import --name $ACR_NAME --source docker.io/djhlee5/project8:latest --image djhlee5/project8:latest --resource-group $MY_RESOURCE_GROUP_NAME

export MY_SN_ID=$(az network vnet subnet list --resource-group $MY_RESOURCE_GROUP_NAME --vnet-name $MY_VNET_NAME --query "[0].id" --output tsv)

az aks create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --name $MY_AKS_CLUSTER_NAME \
    --auto-upgrade-channel stable \
    --enable-cluster-autoscaler \
    --location $REGION \
    --node-count 1 \
    --min-count 1 \
    --max-count 2 \
    --network-plugin azure \
    --network-policy azure \
    --vnet-subnet-id $MY_SN_ID \
    --no-ssh-key \
    --node-vm-size Standard_DS2_v2 \
    --service-cidr 10.255.0.0/24 \
    --dns-service-ip 10.255.0.10 \
    --zones 1 2 3 \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx0-deployment
  labels:
    app: nginx0-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx0
  template:
    metadata:
      labels:
        app: nginx0
    spec:
      containers:
      - name: nginx
        image: ${ACR_NAME}.azurecr.io/nginx:v1
        ports:
        - containerPort: 80
" > acr-nginx.yaml

kubectl create namespace $MY_NAMESPACE

kubectl apply -f acr-nginx.yaml -n $MY_NAMESPACE

export MY_STATIC_IP=$(az network public-ip create --resource-group MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION} --location ${REGION} --name ${MY_PUBLIC_IP_NAME} --dns-name ${MY_DNS_LABEL} --sku Standard --allocation-method static --version IPv4 --zone 1 2 3 --query publicIp.ipAddress -o tsv)

az aks get-credentials --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_AKS_CLUSTER_NAME

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install --cleanup-on-fail --atomic ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$MY_DNS_LABEL \
        --set controller.service.loadBalancerIP=$MY_STATIC_IP \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
        --wait --timeout 10m0s

