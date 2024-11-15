#!/bin/bash

#connect az & login, comment out the below line to run script as a bash file on Azure Cloud Shell
az login

export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
export MY_RESOURCE_GROUP_NAME="Group5_resource_group" 
export REGION="canadacentral"
export REGION_2="eastus"
export DB_KEY_VAULT="WebOpsDBKeyVaultTest$(($RANDOM % 10000 + 1))" #need to change
#export BACKUP_DB_KEY_VAULT="WebOpsDBKeyVaultBackup"
export MY_AKS_CLUSTER_NAME="webopsAKSCluster"
export MY_PUBLIC_IP_NAME="webopsPublicIP"
export MY_DNS_LABEL="webopsdnslabel"
export MY_VNET_NAME="webopsVNet"
export MYSQL_SUBNET_NAME="myMySQLSN"
export AKS_SUBNET_NAME="AKSSubnet"
export AKS_NSG_NAME="AKSSubnetNSG"
export DB_SUBNET_NAME="DBSubnet"
export DB_NSG_NAME="DBSubnetNSG"
export APP_GATEWAY_SUBNET_NAME="AppGatewaySubnet"
export APP_GATEWAY_NSG_NAME="AppGatewaySubnetNSG"
export ACR_SUBNET_NAME="ACRSubnet"
export ACR_NSG_NAME="ACRSubnetNSG"
export PRIVATE_ENDPOINT_SUBNET_NAME="PrivateEndpointSubnet"
export PRIVATE_ENDPOINT_NSG_NAME="PrivateEndpointSubnetNSG"
export MY_VNET_PREFIX="10.$NETWORK_PREFIX.0.0/16"
export AKS_SUBNET_PREFIX="10.$NETWORK_PREFIX.1.0/24"
export DB_SUBNET_PREFIX="10.$NETWORK_PREFIX.2.0/24"
export APP_GATEWAY_SUBNET_PREFIX="10.$NETWORK_PREFIX.3.0/24"
export ACR_SUBNET_PREFIX="10.$NETWORK_PREFIX.4.0/24"
export PRIVATE_ENDPOINT_SUBNET_PREFIX="10.$NETWORK_PREFIX.5.0/24"
export MY_WP_ADMIN_PW="g8tr_p#dw9RDo"
export MY_WP_ADMIN_USER="webops"
export FQDN="$MY_DNS_LABEL.export REGION.cloudapp.azure.com"
export MY_MYSQL_SERVER_NAME="mysqlwpsrvr5"
export MY_MYSQL_DB_NAME="webopswordpressdb"
export MY_MYSQL_ADMIN_USERNAME="developer"
export MY_MYSQL_ADMIN_PW="Naveed@1302"
export MY_MYSQL_HOSTNAME="$MY_MYSQL_SERVER_NAME.mysql.database.azure.com"
export ACR_NAME="webopsacr13"
export MY_NAMESPACE="webops-ns13"
export HSM_NAME="group5hsm"
#The group name here might change based on account, we should try to be consistent with it though
export GROUP_ID="$(az ad group show --group "WebOps" --query "id" --output tsv)"
export SUBSCRIPTIONS_ID="$(az account show --query id --output tsv)"
export MSYS_NO_PATHCONV=1
export ACR_PRIVATE_ENDPOINT_NAME="acrConnection"
export ACR_PRIVATE_ENDPOINT_GROUP_ID="registry"

export DOCKER_HUB_IMAGE_NAME="unaveed1122/webopsimageforwp:v1"

#create resource group
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

#Set up Vnet
az network vnet create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --location $REGION \
    --name $MY_VNET_NAME \
    --address-prefix $MY_VNET_PREFIX

# Create AKS Subnet
az network vnet subnet create \
  --name $AKS_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $AKS_SUBNET_PREFIX

# Create AKS Subnet-NSG
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $AKS_NSG_NAME --location $REGION

# Create Database Subnet
az network vnet subnet create \
  --name $DB_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $DB_SUBNET_PREFIX

# Create Database Subnet-NSG
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $DB_NSG_NAME --location $REGION

# Create Application Gateway Subnet
az network vnet subnet create \
  --name $APP_GATEWAY_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $APP_GATEWAY_SUBNET_PREFIX

# Create Application Gateway Subnet-NSG:
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $APP_GATEWAY_NSG_NAME --location $REGION

# Create Private Endpoint Subnet
az network vnet subnet create \
  --name $PRIVATE_ENDPOINT_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $PRIVATE_ENDPOINT_SUBNET_PREFIX

# Create Private Endpoint Subnet-NSG:
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $PRIVATE_ENDPOINT_NSG_NAME --location $REGION

# Create ACR Subnet (Optional-Will require ACR tier to be Premium)
#az network vnet subnet create \
#  --name $ACR_SUBNET_NAME \
#  --resource-group $MY_RESOURCE_GROUP_NAME \
#  --vnet-name $MY_VNET_NAME \
#  --address-prefixes $ACR_SUBNET_PREFIX

# Create ACR Subnet-NSG: (Optional)
#az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NSG_NAME --location $REGION



#Set up keyvault
az keyvault create -g $MY_RESOURCE_GROUP_NAME --administrators $GROUP_ID -n $DB_KEY_VAULT --location $REGION \
   --enable-rbac-authorization false --enable-purge-protection true

#Assign admin role to group
az role assignment create --assignee-object-id $GROUP_ID \
  --role "Key Vault Administrator" \
  --scope "subscriptions/$SUBSCRIPTIONS_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$DB_KEY_VAULT" 

#Create key in keyvault
export keyIdentifier=$(az keyvault key create --name Group5DBKey -p software --vault-name $DB_KEY_VAULT --query key.kid  --output tsv)

# create identity and save its principalId
export identityPrincipalId=$(az identity create -g $MY_RESOURCE_GROUP_NAME --name group5_identity --location $REGION --query principalId --output tsv)

# add testIdentity as an access policy with key permissions 'Wrap Key', 'Unwrap Key', 'Get' and 'List' inside testVault
az keyvault set-policy -g $MY_RESOURCE_GROUP_NAME \
  -n $DB_KEY_VAULT \
  --object-id $identityPrincipalId \
  --key-permissions wrapKey unwrapKey get list

# create mysql server
az mysql flexible-server create \
    --admin-password $MY_MYSQL_ADMIN_PW \
    --admin-user $MY_MYSQL_ADMIN_USERNAME \
    --auto-scale-iops Disabled \
    --high-availability Disabled \
    --iops 360 \
    --location $REGION \
    --name $MY_MYSQL_SERVER_NAME \
    --database-name $MY_MYSQL_DB_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --sku-name Standard_B2s \
    --storage-auto-grow Disabled \
    --storage-size 20 \
    --vnet $MY_VNET_NAME \
    --subnet $DB_SUBNET_NAME \
    --key $keyIdentifier \
    --identity group5_identity \
    --private-dns-zone $MY_DNS_LABEL.private.mysql.database.azure.com \
    --tier Burstable \
    --version 8.0.21 \
    --yes -o JSON

runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_DB_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done



#TEMPORARY TURN OFF FOR NOW
az mysql flexible-server parameter set \
  --name require_secure_transport \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --server-name $MY_MYSQL_SERVER_NAME \
  --value OFF


# Create Azure Container Registry
az acr create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NAME --sku Basic

# Import Docker image from Docker Hub to ACR
az acr import --name $ACR_NAME --source docker.io/$DOCKER_HUB_IMAGE_NAME --image $DOCKER_HUB_IMAGE_NAME --resource-group $MY_RESOURCE_GROUP_NAME

# Register AKS Provider
az provider register --namespace Microsoft.ContainerService

#create aks cluster
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
    --no-ssh-key \
    --node-vm-size Standard_DS2_v2 \
    --zones 1 2 3 \
    --enable-addons azure-keyvault-secrets-provider \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME \
    --enable-managed-identity \
    --vnet-subnet-id "/subscriptions/$SUBSCRIPTIONS_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$MY_VNET_NAME/subnets/$AKS_SUBNET_NAME"

#get AKS cluster credenials
az aks get-credentials --name $MY_AKS_CLUSTER_NAME --resource-group $MY_RESOURCE_GROUP_NAME

# verify the installation is finished
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

# Create Kubernetes Secret for MySQL Credentials
kubectl create secret generic mysql-secret \
  --from-literal=username=$MY_MYSQL_ADMIN_USERNAME \
  --from-literal=password=$MY_MYSQL_ADMIN_PW


# ERROR: The current registry SKU does not support private endpoint connection. Please upgrade your registry to premium SKU
# Create ACR Private Endpoint
az network private-endpoint create \
  -n $ACR_PRIVATE_ENDPOINT_NAME \
  -g $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --subnet $ACR_SUBNET_NAME \
  --connection-name $ACR_PRIVATE_ENDPOINT_NAME \
  --group-id $ACR_PRIVATE_ENDPOINT_GROUP_ID \
  --private-connection-resource-id "/subscriptions/$SUBSCRIPTIONS_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"


#get managed identity id from aks cluster
export aks_prinipal_id="$(az identity list -g MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION} --query [0].principalId --output tsv)"

#set the key vault certificate officer to k8s cluster managed identity
az role assignment create --assignee-object-id $aks_prinipal_id \
--role "Key Vault Certificates Officer" \
--scope "subscriptions/$SUBSCRIPTIONS_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$DB_KEY_VAULT" 

#create the secret for k8s cluster
az keyvault secret set --vault-name $DB_KEY_VAULT --name AKSClusterSecret --value AKS_sample_secret


#create the access policy for connecting keyvault and k8s managed identiity
az keyvault set-policy -g $MY_RESOURCE_GROUP_NAME \
-n $DB_KEY_VAULT \
--object-id $aks_prinipal_id \
--secret-permissions backup delete get list recover restore set

# test the key is enable and connected to aks cluster
# git clone https://github.com/Azure-Samples/serviceconnector-aks-samples.git
# cd serviceconnector-aks-samples/azure-keyvault-csi-provider
# modify file: secret_provider_class.yaml
# Replace <AZURE_KEYVAULT_NAME> with the name of the key vault you created and connected.
# Replace <AZURE_KEYVAULT_TENANTID> with The directory ID of the aks key vault.
# Replace <AZURE_KEYVAULT_CLIENTID> with identity client ID of the azureKeyvaultSecretsProvider addon.
# Replace <KEYVAULT_SECRET_NAME> with the key vault secret you created. For example, ExampleSecret.
# kubectl apply -f secret_provider_class.yaml
# kubectl apply -f pod.yaml
# kubectl get pod/sc-demo-keyvault-csi
# kubectl exec sc-demo-keyvault-csi -- ls /mnt/secrets-store/
# kubectl exec sc-demo-keyvault-csi -- cat /mnt/secrets-store/AKSClusterSecret #fetch the data

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: akswordpress-deployment
spec:
  replicas: 2  
  selector:
    matchLabels:
      app: akswordpress
  template:
    metadata:
      labels:
        app: akswordpress
    spec:
      containers:
      - name: akswordpress
        image: ${ACR_NAME}.azurecr.io/${DOCKER_HUB_IMAGE_NAME}
        env:
        - name: WORDPRESS_DB_HOST
          value: ${MY_MYSQL_HOSTNAME}
        - name: WORDPRESS_DB_NAME
          value: ${MY_MYSQL_DB_NAME}
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: username
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1"
" > deployment.yaml

echo "apiVersion: v1
kind: Service
metadata:
  name: akswordpress-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: akswordpress
" > service.yaml

# Apply the Deployment and Service in Kubernetes
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

# Set static IP address
export MY_STATIC_IP=$(az network public-ip create --resource-group MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION} --location ${REGION} --name ${MY_PUBLIC_IP_NAME} --dns-name ${MY_DNS_LABEL} --sku Standard --allocation-method static --version IPv4 --zone 1 2 3 --query publicIp.ipAddress -o tsv)

# Create Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install --cleanup-on-fail --atomic ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$MY_DNS_LABEL \
        --set controller.service.loadBalancerIP=$MY_STATIC_IP \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
        --wait --timeout 10m0s

# Get Service Info
kubectl get service