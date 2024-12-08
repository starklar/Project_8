#connect az & login, comment out the below line to run script as a bash file on Azure Cloud Shell
#az login

# Step 01:
# Create DNS-Zone and make sure it's working
az network dns zone create \
  --resource-group $MY_DNS_RESOURCE_GROUP_NAME \
  --name $WEBSITE_NAME

# Step 02
#create resource group
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

###########################################
# !!! SETTING VNET, SUBNETS & NSG'S !!!   #
###########################################

# Step 03
#Set up Vnet
az network vnet create \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --location $REGION \
    --name $MY_VNET_NAME \
    --address-prefix $VNET_CIDR

# Subnetting and NSG's with Rules respectively
# SUBNET 01
# Create AKS Subnet
az network vnet subnet create \
  --name $AKS_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $AKS_SUBNET_PREFIX \
  --private-endpoint-network-policies Disabled

# Create AKS Subnet-NSG
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $AKS_NSG_NAME --location $REGION

#Inbound Rules:
# Rule 100: Allow Any Custom Inbound (Any source, any destination)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name AllowAnyCustomAnyInbound \
  --priority 100 \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*" \
  --access Allow

# Rule 110: Allow HTTP Inbound (Port 80)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_HTTP_Inbound \
  --priority 110 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --destination-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-port-ranges 80 \
  --access Allow

# Rule 120: Allow HTTPS Inbound (Port 443)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_HTTPS_Inbound \
  --priority 120 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --destination-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-port-ranges 443 \
  --access Allow

# Rule 130: Allow MySQL Inbound (Port 3306 from DB subnet to AKS subnet)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_MySQL_Inbound \
  --priority 130 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes $DB_SUBNET_PREFIX \
  --destination-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-port-ranges 3306 \
  --access Allow

# Rule 140: Allow AKS Internal Traffic Inbound (Any port from AKS subnet to AKS subnet)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_AKS_Internal_Traffic_Inbound \
  --priority 140 \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-port-ranges "*" \
  --access Allow

# Outbound Rules
# Rule 100: Allow AKS to Azure Services (Outbound to AzureCloud)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_AKS_To_AzureServices \
  --priority 100 \
  --direction Outbound \
  --protocol "*" \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes AzureCloud \
  --destination-port-ranges "*" \
  --access Allow

# Rule 110: Allow AKS to Private Endpoint ACR (Outbound on port 443)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_AKS_to_PrivateEndpoint_ACR \
  --priority 110 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $ACR_SUBNET_PREFIX \
  --destination-port-ranges 443 \
  --access Allow

# Rule 120: Allow AKS to Private Endpoint DB (Outbound on port 3306)
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $AKS_NSG_NAME \
  --name Allow_AKS_to_PrivateEndpoint_DB \
  --priority 120 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $DB_SUBNET_PREFIX \
  --destination-port-ranges 3306 \
  --access Allow

# SUBNET 02
# Create Database Subnet
az network vnet subnet create \
   --name $DB_SUBNET_NAME \
   --resource-group $MY_RESOURCE_GROUP_NAME \
   --vnet-name $MY_VNET_NAME \
   --address-prefixes $DB_SUBNET_PREFIX \
   --private-endpoint-network-policies Disabled

# Create Database Subnet-NSG
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $DB_NSG_NAME --location $REGION

# Create NSG Rule: To Allow Traffic from AKS in DB_NSG and Block all other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $DB_NSG_NAME \
  --name Allow_Traffic_From_AKS \
  --priority 100 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $DB_SUBNET_PREFIX \
  --destination-port-ranges 3306 \
  --access Allow

# Block All other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $DB_NSG_NAME \
  --name Deny_All \
  --priority 4096 \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*' \
  --access Deny

# SUBNET 03
# Create ACR Subnet 
az network vnet subnet create \
  --name $ACR_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $ACR_SUBNET_PREFIX \
  --private-endpoint-network-policies Disabled

# Create ACR Subnet-NSG:
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NSG_NAME --location $REGION

# Create NSG Rule: To Allow Traffic from AKS in ACR_NSG and Block all other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $ACR_NSG_NAME \
  --name Allow_Traffic_From_AKS \
  --priority 100 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $ACR_SUBNET_PREFIX \
  --destination-port-ranges 443 \
  --access Allow

# Block All other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $ACR_NSG_NAME \
  --name Deny_All \
  --priority 4095 \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*' \
  --access Deny

# SUBNET 02
# Create Key Vault Subnet
az network vnet subnet create \
   --name $KV_SUBNET_NAME \
   --resource-group $MY_RESOURCE_GROUP_NAME \
   --vnet-name $MY_VNET_NAME \
   --address-prefixes $KV_SUBNET_PREFIX \
   --private-endpoint-network-policies Disabled

# Create Database Subnet-NSG
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $KV_NSG_NAME --location $REGION

# Create NSG Rule: To Allow Traffic from AKS in DB_NSG and Block all other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $KV_NSG_NAME \
  --name Allow_Traffic_From_AKS \
  --priority 100 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes $AKS_SUBNET_PREFIX \
  --destination-address-prefixes $KV_SUBNET_PREFIX \
  --destination-port-ranges 443 \
  --access Allow

# Block All other
az network nsg rule create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --nsg-name $KV_NSG_NAME \
  --name Deny_All \
  --priority 4096 \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*' \
  --access Deny

# SUBNET 05
# Create VM Subnet 
az network vnet subnet create \
  --name $VM_SUBNET_NAME \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --vnet-name $MY_VNET_NAME \
  --address-prefixes $VM_SUBNET_PREFIX \
  --private-endpoint-network-policies Disabled

# Create VM Subnet-NSG:
az network nsg create --resource-group $MY_RESOURCE_GROUP_NAME --name $VM_NSG_NAME --location $REGION
