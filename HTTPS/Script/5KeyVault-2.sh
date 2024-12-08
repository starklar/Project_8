########################
# !!! CREATE SECRETS !!!
########################

# Step 03: Create Secrets
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "mysql-db-username" --value "developer"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "mysql-db-password" --value "webops_mysqlpw"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name DigiCertGlobalRootCA --file DigiCertGlobalRootCA.crt.pem

# For Verification
# az keyvault secret show --name mysql-db-username --vault-name $KEY_VAULT_NAME
# az keyvault secret show --name mysql-db-password --vault-name $KEY_VAULT_NAME
