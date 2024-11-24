#!/bin/bash

# NOTE: If you see: bash: ./project_setup.sh: /bin/bash^M: bad interpreter: No such file or directory
# run: sed -i -e 's/\r$//' project_setup.sh

#connect az & login, comment out the below line to run script as a bash file on Azure Cloud Shell
az login

export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
export MY_RESOURCE_GROUP_NAME="Group5_resource_group_anthony" 
export REGION="canadacentral"
export REGION_2="eastus"
export DB_KEY_VAULT="WebOpsDBKeyVaultTest$(($RANDOM % 10000 + 1))" #need to change
#export BACKUP_DB_KEY_VAULT="WebOpsDBKeyVaultBackup"
export MY_AKS_CLUSTER_NAME="webopsAKSCluster"
export MY_PUBLIC_IP_NAME="webopsPublicIP"
export MY_DNS_LABEL="webopsdnslabel"
export AKS_DNS_LABEL="webopsaksdnslabel"
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
export VM_NAME="Webops_VM"
export ORIGIN_GROUP_NAME="webopsOriginGroup"
export PRIMARY_ORIGIN_NAME="primaryOrigin"
export ROUTE_NAME="webOpsMainRoute"
export WAF_NAME="frontDoorWAF"
export FRONT_DOOR_NAME="webopsFrontDoor"
export FRONT_DOOR_ENDPOINT_NAME="webopsFrontEnd"
export FRONT_DOOR_SECURITY_POLICY_NAME="fd-sec-po"
export FRONT_DOOR_RULE_SET_NAME="frontDoorRuleSet"
export DOCKER_HUB_IMAGE_NAME="unaveed1122/webopsimageforwp:v1"
export vm_admin_pw="webops_vm_1234"

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

# # Create Database Subnet
# az network vnet subnet create \
#   --name $DB_SUBNET_NAME \
#   --resource-group $MY_RESOURCE_GROUP_NAME \
#   --vnet-name $MY_VNET_NAME \
#   --address-prefixes $DB_SUBNET_PREFIX \


# # Create Database Subnet-NSG
# az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $DB_NSG_NAME --location $REGION

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
  --address-prefixes $PRIVATE_ENDPOINT_SUBNET_PREFIX \
  --disable-private-endpoint-network-policies true

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


# # Create the VM for testing the connection between private endpoing and mysql server
# az vm create \
#   -g $MY_RESOURCE_GROUP_NAME \
#   -n $VM_NAME \
#   --image Win2019Datacenter \
#   --location $REGION \
#   --admin-password $vm_admin_pw

# #get vm public ip address
# export vm_puiblic_ip="$(az vm list-ip-addresses -g $MY_RESOURCE_GROUP_NAME -n $VM_NAME --query [].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)"

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
    --key $keyIdentifier \
    --identity group5_identity \
    --tier Burstable \
    --version 8.0.21 \
    --yes -o JSON  \
    --public-access $vm_puiblic_ip
    #--private-dns-zone $MY_DNS_LABEL.private.mysql.database.azure.com \
    #--vnet $MY_VNET_NAME \
    #--subnet $DB_SUBNET_NAME \
  

runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_SERVER_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done


#create private endpoint for az mysql
az network private-endpoint create \
    --name DBPrivateEndpoint \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --vnet-name $MY_VNET_NAME  \
    --subnet $AKS_SUBNET_NAME \
    --private-connection-resource-id $(az resource show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_SERVER_NAME --resource-type "Microsoft.DBforMySQL/flexibleServers" --query "id" -o tsv) \
    --group-id mysqlServer \
    --connection-name DBConnection \
    --location $REGION \
    --subscription $SUBSCRIPTIONS_ID

#Configure private DNS Zone
az network private-dns zone create --resource-group $MY_RESOURCE_GROUP_NAME \
   --name privatelink.mysql.database.azure.com


az network private-dns link vnet create --resource-group $MY_RESOURCE_GROUP_NAME \
   --zone-name  privatelink.mysql.database.azure.com \
   --name DBDNSLink \
   --virtual-network $MY_VNET_NAME \
   --registration-enabled false

export networkInterfaceId=$(az network private-endpoint show --name DBPrivateEndpoint --resource-group $MY_RESOURCE_GROUP_NAME --query 'networkInterfaces[0].id' -o tsv)
export private_ip=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)

az network private-dns record-set a create --name $MY_MYSQL_SERVER_NAME \
    --zone-name privatelink.mysql.database.azure.com \
    --resource-group $MY_RESOURCE_GROUP_NAME

az network private-dns record-set a add-record --record-set-name $MY_MYSQL_SERVER_NAME \
    --zone-name privatelink.mysql.database.azure.com \
    -g $MY_RESOURCE_GROUP_NAME \
    -a $private_ip

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
    --service-cidr 10.255.0.0/24 \
    --dns-service-ip 10.255.0.10 \
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

#Create K8s keyvault
az keyvault create -g $MY_RESOURCE_GROUP_NAME --administrators $GROUP_ID -n $DB_KEY_VAULT --location $REGION \
  --enable-rbac-authorization false
  
# Create Kubernetes Secret for MySQL Credentials
kubectl create secret generic mysql-secret \
  --from-literal=username=$MY_MYSQL_ADMIN_USERNAME \
  --from-literal=password=$MY_MYSQL_ADMIN_PW


# ERROR: The current registry SKU does not support private endpoint connection. Please upgrade your registry to premium SKU
# Create ACR Private Endpoint
#az network private-endpoint create \
#  -n $ACR_PRIVATE_ENDPOINT_NAME \
#  -g $MY_RESOURCE_GROUP_NAME \
#  --vnet-name $MY_VNET_NAME \
#  --subnet $ACR_SUBNET_NAME \
#  --connection-name $ACR_PRIVATE_ENDPOINT_NAME \
#  --group-id $ACR_PRIVATE_ENDPOINT_GROUP_ID \
#  --private-connection-resource-id "/subscriptions/$SUBSCRIPTIONS_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"

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
          value: ${MY_MYSQL_SERVER_NAME}.privatelink.mysql.database.azure.com
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
export MY_STATIC_IP=$(az network public-ip create --resource-group MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION} --location ${REGION} --name ${MY_PUBLIC_IP_NAME} --dns-name ${AKS_DNS_LABEL} --sku Standard --allocation-method static --version IPv4 --zone 1 2 3 --query publicIp.ipAddress -o tsv)

# Create Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install --cleanup-on-fail --atomic ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$AKS_DNS_LABEL \
        --set controller.service.loadBalancerIP=$MY_STATIC_IP \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
        --wait --timeout 10m0s

helm install quickstart ingress-nginx/ingress-nginx

# Get Service Info
kubectl get service



#Set up Front door, Standard version
# Change sku to: Premium_AzureFrontDoor, for managed rules
az afd profile create \
    --profile-name $FRONT_DOOR_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --sku Standard_AzureFrontDoor




# Create Front Door Endpoint
az afd endpoint create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --endpoint-name $FRONT_DOOR_ENDPOINT_NAME \
    --profile-name $FRONT_DOOR_NAME \
    --enabled-state Enabled


#Create an origin group that defines the traffic and expected responses for our app
az afd origin-group create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --origin-group-name $ORIGIN_GROUP_NAME \
    --profile-name $FRONT_DOOR_NAME \
    --probe-request-type GET \
    --probe-protocol Http \
    --probe-interval-in-seconds 60 \
    --probe-path / \
    --sample-size 4 \
    --successful-samples-required 3 \
    --additional-latency-in-milliseconds 50


# Create origins for each AKS
export PRIMARY_ORIGIN_HOST_NAME=$(kubectl get service  | awk '$1=="akswordpress-service"{print $4}')

az afd origin create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --host-name $PRIMARY_ORIGIN_HOST_NAME \
    --origin-host-header $PRIMARY_ORIGIN_HOST_NAME \
    --profile-name $FRONT_DOOR_NAME \
    --origin-group-name $ORIGIN_GROUP_NAME \
    --origin-name $PRIMARY_ORIGIN_NAME \
    --priority 1 \
    --weight 1000 \
    --enabled-state Enabled \
    --http-port 80 \
    --https-port 443


# Create route to forwards requests from the endpoint to origin group.
# TODO: Add " Https" to --supported-protocols once that's ready
az afd route create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --profile-name $FRONT_DOOR_NAME \
    --endpoint-name $FRONT_DOOR_ENDPOINT_NAME \
    --forwarding-protocol MatchRequest \
    --route-name $ROUTE_NAME \
    --origin-group $ORIGIN_GROUP_NAME \
    --supported-protocols Http  \
    --link-to-default-domain Enabled 

# Create WAF for Front Door
# Change sku to: Premium_AzureFrontDoor, for managed rules
az network front-door waf-policy create \
    --name $WAF_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --sku Standard_AzureFrontDoor \
    --disabled false \
    --mode Prevention

# Apply WAF policy to the endpoint
az afd security-policy create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --profile-name $FRONT_DOOR_NAME \
    --security-policy-name $FRONT_DOOR_SECURITY_POLICY_NAME \
    --domains /subscriptions/$SUBSCRIPTIONS_ID/resourcegroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.Cdn/profiles/$FRONT_DOOR_NAME/afdEndpoints/$FRONT_DOOR_ENDPOINT_NAME \
    --waf-policy /subscriptions/$SUBSCRIPTIONS_ID/resourcegroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.Network/frontdoorwebapplicationfirewallpolicies/$WAF_NAME


# Create WAF custom rules
# Block traffic from anywhere that isn't Canada
az network front-door waf-policy rule create \
    --policy-name $WAF_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --name BlockForeignCountriesRule \
    --action Block \
    --priority 500 \
    --rule-type MatchRule \
    --defer

az network front-door waf-policy rule match-condition add \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --policy-name $WAF_NAME \
    --name BlockForeignCountriesRule \
    --match-variable RemoteAddr \
    --operator GeoMatch \
    --values CA \
    --negate true

# Block non-GET traffic
az network front-door waf-policy rule create \
    --policy-name $WAF_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --name BlockNonGET \
    --action Block \
    --priority 300 \
    --rule-type MatchRule \
    --defer

az network front-door waf-policy rule match-condition add \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --policy-name $WAF_NAME \
    --name BlockNonGET \
    --match-variable RequestMethod \
    --operator Equal \
    --values GET \
    --negate true


# Rate Limit Uri
az network front-door waf-policy rule create \
    --policy-name $WAF_NAME \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --name RateLimitUri \
    --action Block \
    --priority 800 \
    --rule-type RateLimitRule \
    --rate-limit-duration 1 \
    --rate-limit-threshold 100 \
    --defer

az network front-door waf-policy rule match-condition add \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --policy-name $WAF_NAME \
    --name RateLimitUri \
    --match-variable RemoteAddr \
    --operator IPMatch \
    --values 255.255.255.255/32 \
    --negate true


# Get hostname for Front Door endpoint
az afd endpoint show --resource-group $MY_RESOURCE_GROUP_NAME --profile-name $FRONT_DOOR_NAME --endpoint-name $FRONT_DOOR_ENDPOINT_NAME