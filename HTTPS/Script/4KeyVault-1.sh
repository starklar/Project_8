#########################
# !!! SET UP KEYVAULT !!!
#########################
# Prerequiste to make sure correct subscription is sleected
az account set --subscription $SUBSCRIPTION_ID

# Step 1: Create up keyvault
az keyvault create -g $MY_RESOURCE_GROUP_NAME -n $KEY_VAULT_NAME --location $REGION --enable-rbac-authorization

# you may need to recover if already created and deleted within 90 days unless changing the name of Key Vault
# az keyvault recover --name $KEY_VAULT_NAME --resource-group $MY_RESOURCE_GROUP_NAME 
# and make it public again
# az keyvault update --resource-group $MY_RESOURCE_GROUP_NAME --name $KEY_VAULT_NAME --public-network-access Enabled

# Step 02: Create KV Managed Identity
az identity create --name $UAMI --resource-group $MY_RESOURCE_GROUP_NAME

##### IMPORTANT #####
# !!!Go to Keyvault and assign keyvault administrator role to newly created UAMI and user ID that you are using!!!
# To Do Manually --> Go to Keyvault --> Accesscontrol IAM --> Add Role Assigment --> Keyvault Administraot--> User --> Select your ID --> Select managed Identity too--> Review and Create 

# To do through script
# export KEYVAULT_SCOPE=$(az keyvault show --name $KEY_VAULT_NAME --query id -o tsv)
# az role assignment create --role "Key Vault Administrator" --assignee $KV_USER_ASSIGNED_CLIENT_ID --scope $KEYVAULT_SCOPE

