#connect az & login

az login

export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
export MY_RESOURCE_GROUP_NAME="Group5_resource_group" 
export REGION="canadacentral"
export REGION_2="eastus"
export DB_KEY_VAULT="WebOpsDBKeyVaultTest7" #need to change
#export BACKUP_DB_KEY_VAULT="WebOpsDBKeyVaultBackup"
export K8s_KEY_VAULT="WebOpsK8sKeyVault0"
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
export GROUP_ID="$(az ad group show --group "Group5" --query "id" --output tsv)"
export subscriptions_ID="$(az account show --query id --output tsv)"


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
  --scope "subscriptions/$subscriptions_ID/resourceGroups/Group5_resource_group/providers/Microsoft.KeyVault/vaults/$DB_KEY_VAULT" 

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

runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MY_MYSQL_DB_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done

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
  export aks_prinipal_id="$(az identity list -g 'MC_Group5_resource_group_webopsAKSCluster_canadacentral' --query [0].principalId --output tsv)"

  #set the key vault certificate officer to k8s cluster managed identity
  az role assignment create --assignee-object-id $aks_prinipal_id \
  --role "Key Vault Certificates Officer" \
  --scope "subscriptions/$subscriptions_ID/resourceGroups/Group5_resource_group/providers/Microsoft.KeyVault/vaults/$K8s_KEY_VAULT" 
  
  #create the secret for k8s cluster
  az keyvault secret set --vault-name $K8s_KEY_VAULT --name AKSClusterSecret --value AKS_sample_secret


  #create the access policy for connecting keyvault and k8s managed identiity
  az keyvault set-policy -g $MY_RESOURCE_GROUP_NAME \
  -n $K8s_KEY_VAULT \
  --object-id $aks_prinipal_id \
  --secret-permissions backup delete get list recover restore set

  #get aks resource group name
  export aks_rg_name="$(az group show --name "MC_Group5_resource_group_webopsAKSCluster_canadacentral" --query name --output tsv)"

  # test the key is enable and connected to aks cluster
  # git clone https://github.com/Azure-Samples/serviceconnector-aks-samples.git
  # cd serviceconnector-aks-samples/azure-keyvault-csi-provider
  # Replace <AZURE_KEYVAULT_NAME> with the name of the key vault you created and connected.
  # Replace <AZURE_KEYVAULT_TENANTID> with the tenant ID of the key vault.
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