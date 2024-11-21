#connect az & login

# NOTE: If you see: bash: ./project_setup.sh: /bin/bash^M: bad interpreter: No such file or directory
# run: sed -i -e 's/\r$//' project_setup.sh

#connect az & login, comment out the below line to run script as a bash file on Azure Cloud Shell
az login

export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
export MY_RESOURCE_GROUP_NAME="Group5_resource_group" 
export REGION="canadacentral"
export REGION_2="eastus"
export DB_KEY_VAULT="WebOpsDBKeyVaultTest8" #need to change
#export BACKUP_DB_KEY_VAULT="WebOpsDBKeyVaultBackup"
export K8s_KEY_VAULT="WebOpsK8sKeyVault1"
export MY_AKS_CLUSTER_NAME="webopsAKSCluster"
export MY_PUBLIC_IP_NAME="webopsPublicIP"
export MY_DNS_LABEL="webopsdnslabel"
export MY_VNET_NAME="webopsVNet"
export MY_VNET_PREFIX="10.$NETWORK_PREFIX.0.0/16"
export MY_SN_NAME="webopsSN"
export MY_SN_PREFIX="10.$NETWORK_PREFIX.0.0/22"
export MY_WP_ADMIN_PW="g8tr_p#dw9RDo"
export MY_WP_ADMIN_USER="webops"
export FQDN="$MY_DNS_LABEL.export REGION.cloudapp.azure.com"
export MY_MYSQL_DB_NAME="webopsdb"
export MY_MYSQL_ADMIN_USERNAME="groupadmin"
export MY_MYSQL_ADMIN_PW="#admin96705"
export MY_MYSQL_SN_NAME="myMySQLSN"
export MY_MYSQL_HOSTNAME="export MY_MYSQL_DB_NAME.mysql.database.azure.com"
export ACR_NAME="webopsacr"
export MY_NAMESPACE="webops-ns"
export HSM_NAME="group5hsm"
#The group name here might change based on account, we should try to be consistent with it though
export GROUP_ID="$(az ad group show --group "WebOps" --query "id" --output tsv)"
export SUBSCRIPTIONS_ID="$(az account show --query id --output tsv)"
export MSYS_NO_PATHCONV=1
export ACR_PRIVATE_ENDPOINT_NAME="acrConnection"
export ACR_PRIVATE_ENDPOINT_GROUP_ID="registry"
export ORIGIN_GROUP_NAME="webopsOriginGroup"
export PRIMARY_ORIGIN_NAME="primaryOrigin"
export ROUTE_NAME="webOpsMainRoute"
export WAF_NAME="frontDoorWAF"
export FRONT_DOOR_NAME="webopsFrontDoor"
export FRONT_DOOR_ENDPOINT_NAME="webopsFrontEnd"
export FRONT_DOOR_SECURITY_POLICY_NAME="fd-sec-po"
export FRONT_DOOR_RULE_SET_NAME="frontDoorRuleSet"

export DOCKER_HUB_IMAGE_NAME="unaveed1122/webopsimageforwp:v1"

#create resource group
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

#Set up Vnet
az network vnet create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --location $REGION \
    --name $MY_VNET_NAME \
    --address-prefix $MY_VNET_PREFIX \
    --subnet-name $MY_SN_NAME \
    --subnet-prefixes $MY_SN_PREFIX

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
    --name $MY_MYSQL_DB_NAME \
    --database-name webopswordpressdb \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --sku-name Standard_B2s \
    --storage-auto-grow Disabled \
    --storage-size 20 \
    --subnet $MY_MYSQL_SN_NAME \
    --key $keyIdentifier \
    --identity group5_identity \
    --private-dns-zone $MY_DNS_LABEL.private.mysql.database.azure.com \
    --tier Burstable \
    --version 8.0.21 \
    --vnet $MY_VNET_NAME \
    --yes -o JSON

runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_SERVER_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done

az acr create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NAME --sku Basic

az acr import --name $ACR_NAME --source docker.io/djhlee5/project8:latest --image djhlee5/project8:latest --resource-group $MY_RESOURCE_GROUP_NAME

export MY_SN_ID="$(az network vnet subnet list --resource-group $MY_RESOURCE_GROUP_NAME --vnet-name $MY_VNET_NAME --query "[0].id" --output tsv)"

export MSYS_NO_PATHCONV=1
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
    --vnet-subnet-id $MY_SN_ID \
    --no-ssh-key \
    --node-vm-size Standard_DS2_v2 \
    --service-cidr 10.255.0.0/24 \
    --dns-service-ip 10.255.0.10 \
    --zones 1 2 3 \
    --enable-addons azure-keyvault-secrets-provider \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME \
    --enable-managed-identity
  
#get AKS cluster credenials
az aks get-credentials --name $MY_AKS_CLUSTER_NAME --resource-group $MY_RESOURCE_GROUP_NAME

# verify the installation is finished
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

#Create K8s keyvault
az keyvault create -g $MY_RESOURCE_GROUP_NAME --administrators $GROUP_ID -n $K8s_KEY_VAULT --location $REGION \
  --enable-rbac-authorization false

#get managed identity id from aks cluster
export aks_prinipal_id="$(az identity list -g MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION} --query [0].principalId --output tsv)"

#set the key vault certificate officer to k8s cluster managed identity
az role assignment create --assignee-object-id $aks_prinipal_id \
  --role "Key Vault Certificates Officer" \
  --scope "subscriptions/$subscriptions_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$K8s_KEY_VAULT" 

#create the secret for k8s cluster
az keyvault secret set --vault-name $K8s_KEY_VAULT --name AKSClusterSecret --value AKS_sample_secret


#create the access policy for connecting keyvault and k8s managed identiity
az keyvault set-policy -g $MY_RESOURCE_GROUP_NAME \
  -n $K8s_KEY_VAULT \
  --object-id $aks_prinipal_id \
  --secret-permissions backup delete get list recover restore set

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

