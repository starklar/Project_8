###################################################################################
# Create Private Endpoints for AKS to ACR, AKS to Azure MySql and AKS to KeyVault #
###################################################################################

#########################################################################
# Creating Database Private Endpoint with private DNS zone 
# Navigate to folder containing DBPvtEndpoint dbtemplate and dbparameters
az deployment group create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --template-file dbtemplate.json \
  --parameters dbparameters.json

# Get the Private IP of the MySQL Endpoint
export DB_NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $MySQL_PRIVATE_ENDPOINT_NAME --resource-group $MY_RESOURCE_GROUP_NAME --query 'networkInterfaces[0].id' -o tsv)
export PRIVATE_IP_DB_ENDPOINT=$(az resource show --ids $DB_NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo $PRIVATE_IP_DB_ENDPOINT

############################################################################
# Creating ACR Private Endpoint with private DNS zone 
# Navigate to folder containing ACRPvtEndpoint acrtemplate and acrparameters
az deployment group create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --template-file acrtemplate.json \
  --parameters acrparameters.json

# Get the Private IP of the ACR Private Endpoint
export ACR_NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $ACR_PRIVATE_ENDPOINT_NAME --resource-group $MY_RESOURCE_GROUP_NAME --query 'networkInterfaces[0].id' -o tsv)
export PRIVATE_IP_ACR_ENDPOINT=$(az resource show --ids $ACR_NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo $PRIVATE_IP_ACR_ENDPOINT

#########################################################################
# Creating KeyVault Private Endpoint with private DNS zone 
# Navigate to folder containing KVPvtEndpoint kvtemplate and kvparameters
az deployment group create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --template-file kvtemplate.json \
  --parameters kvparameters.json

# Get the Private IP of the ACR Private Endpoint
export KV_NETWORK_INTERFACE_ID=$(az network private-endpoint show --name $KV_PRIVATE_ENDPOINT_NAME --resource-group $MY_RESOURCE_GROUP_NAME --query 'networkInterfaces[0].id' -o tsv)
export PRIVATE_IP_KV_ENDPOINT=$(az resource show --ids $KV_NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo $PRIVATE_IP_KV_ENDPOINT

#####################################################################
# Truning OFF Public Access to all resources having Private Endpoints
# Turn Off Public Access to ACR after having private endpoint ready
az acr update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $ACR_NAME \
  --public-network-enabled false

# Turn Off Public Access to Database
az mysql flexible-server update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $MYSQL_SERVER_NAME \
  --public-access Disabled

# Turn Off Public Access to Key Vault
az keyvault update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $KEY_VAULT_NAME \
  --public-network-access Disabled

###################################################################
# Attach all NSG's with rules created earlier to respective subnets
# Attach NSG to AKS Subnet
az network vnet subnet update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --name $AKS_SUBNET_NAME \
  --network-security-group $AKS_NSG_NAME

# Attach NSG to Database Subnet
az network vnet subnet update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --name $DB_SUBNET_NAME \
  --network-security-group $DB_NSG_NAME

# Attach NSG to ACR Subnet
az network vnet subnet update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --name $ACR_SUBNET_NAME \
  --network-security-group $ACR_NSG_NAME

# Attach NSG to KV Subnet
az network vnet subnet update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --name $KV_SUBNET_NAME \
  --network-security-group $KV_NSG_NAME

# Attach NSG to VM Subnet
az network vnet subnet update \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --name $VM_SUBNET_NAME \
  --network-security-group $VM_NSG_NAME