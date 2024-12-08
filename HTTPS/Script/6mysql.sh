####################################################################################
# !!! CREATING AND CONFIGURING AZURE MYSQL FLEXIBLE SERVER WITH PRIVATE ENDPOINT !!!
####################################################################################

# Get the secret's value from KeyVault for username and password
MYSQL_ADMIN_USERNAME=$(az keyvault secret show \
  --vault-name $KEY_VAULT_NAME \
  --name mysql-db-username \
  --query value -o tsv)

MYSQL_ADMIN_PW=$(az keyvault secret show \
  --vault-name $KEY_VAULT_NAME \
  --name mysql-db-password \
  --query value -o tsv)


# Create MySQL Flexible Server
az mysql flexible-server create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --location $REGION \
  --name $MYSQL_SERVER_NAME \
  --admin-user $MYSQL_ADMIN_USERNAME \
  --admin-password $MYSQL_ADMIN_PW \
  --database-name $MYSQL_DB_NAME \
  --auto-scale-iops Enabled \
  --high-availability Disabled \
  --zone 1 \
  --sku-name Standard_B2s \
  --storage-auto-grow Enabled \
  --storage-size 20 \
  --tier Burstable \
  --version 8.0.21 \
  --yes -o JSON


# Clear sensitive environment variables after use
unset MYSQL_ADMIN_USERNAME
unset MYSQL_ADMIN_PW

# Step 2: Monitor MySQL Server State until it is 'Ready'
# This loop waits for the MySQL server to reach the 'Ready' state, checking every 10 seconds.
# This ensures that the server is fully created and operational before proceeding.
runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(az mysql flexible-server show -g $MY_RESOURCE_GROUP_NAME -n $MYSQL_SERVER_NAME --query state -o tsv); echo $STATUS; if [ "$STATUS" = 'Ready' ]; then break; else sleep 10; fi; done
