#!/bin/bash

# NOTE: If you see: bash: ./project_setup.sh: /bin/bash^M: bad interpreter: No such file or directory
# run: sed -i -e 's/\r$//' project_setup.sh

# These two variable are just for reference to use the value otherrwise it will be created as secret during KeyVault creation and will use from there only - no direct propagation
MYSQL_ADMIN_USERNAME="developer"
MYSQL_ADMIN_PW="webops_mysqlpw"
WP_ADMIN_USERNAME="adminwebops"
WP_ADMIN_PASSWORD="webops_wppw"

#Declare Variables
export SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
export SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export WEBSITE_NAME="Your Name"
export MY_RESOURCE_GROUP_NAME="WebOps_Resource_Group_Yourname"
export REGION="canadacentral"
###### VNET #####
export MY_VNET_NAME="webopsVNet"
export VNET_CIDR="10.1.0.0/16"
#Subnets
export AKS_SUBNET_NAME="AKSSubnet"
export DB_SUBNET_NAME="DBSubnet"
export ACR_SUBNET_NAME="ACRSubnet"
export KV_SUBNET_NAME="KVSubnet"
export VM_SUBNET_NAME="VMSubnet"
# Prefix
export AKS_SUBNET_PREFIX="10.1.1.0/24"
export DB_SUBNET_PREFIX="10.1.2.0/24"
export ACR_SUBNET_PREFIX="10.1.3.0/24"
export KV_SUBNET_PREFIX="10.1.4.0/24"
export VM_SUBNET_PREFIX="10.1.5.0/24"
#NSG's
export AKS_NSG_NAME="AKSSubnetNSG"
export DB_NSG_NAME="DBSubnetNSG"
export ACR_NSG_NAME="ACRSubnetNSG"
export KV_NSG_NAME="KVSubnetNSG"
export VM_NSG_NAME="VMSubnetNSG"
# Private Endpoints
export MySQL_PRIVATE_ENDPOINT_NAME="DBPrivateEndpoint"
export MYSQL_RESOURCE_TYPE="Microsoft.DBforMySQL/flexibleServers"
export PRIVATE_DNS_ZONE_NAME="privatelink.mysql.database.azure.com"
export ACR_PRIVATE_ENDPOINT_NAME="ACRPrivateEndpoint"
export ACR_PE_CONNECTION_NAME="ACRConnectionPE"
export ACR_PRIVATE_ENDPOINT_GROUP_ID="registry"
export KV_PRIVATE_ENDPOINT_NAME="KVPrivateEndpoint"
export KV_PE_CONNECTION_NAME="KVConnectionPE"
export KV_PRIVATE_ENDPOINT_GROUP_ID="vault"
# Key_Vault
export KEY_VAULT_NAME="WebOpsKeyVaultYourname"
export UAMI="azurekeyvaultsecretsprovider-${MY_AKS_CLUSTER_NAME}"
###### VM #####
export MY_VM_NAME="Webops_VM"
export MY_VM_USERNAME="webopsuser"
export MY_VM_ADMIN_PW="Webops_vm1pw"
###### ACR ######
export ACR_NAME="webopsacryourname"
export DOCKER_HUB_IMAGE_NAME="unaveed1122/project8wp:v1"
###### Azure MySQL #####
export MY_DNS_ZONE_NAME="Your Domain"
export MYSQL_SERVER_NAME="mysqlwpsrvryourname"
export MYSQL_HOSTNAME="${MYSQL_SERVER_NAME}.mysql.database.azure.com"
export MYSQL_DB_NAME="webopswordpressdb"
export WP_TITLE="uShipiDeliver by WebOps"
export WORDPRESS_EMAIL="ushipideliver@hotmail.com"
###### AKS ######
export MY_AKS_CLUSTER_NAME="webopsAKSCluster"
export AKS_DNS_PREFIX="webopsAKSCluster-dns"
export AKSRESOURCEGROUPNAME="MC_${MY_RESOURCE_GROUP_NAME}_${MY_AKS_CLUSTER_NAME}_${REGION}"
export MY_PUBLIC_IP_NAME="myAKSPublicIPForIngress"
export MSI_NAME="group5-externaldns-access-to-dnszones"
export MY_DNS_RESOURCE_GROUP_NAME="dns-zones"  # Resource group for DNS Zones
export MY_MONITORING_WORKSPACE_NAME="aks-monitoring"
