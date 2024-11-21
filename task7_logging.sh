#!/bin/bash

# 1. Create Log Analytics workspace
RESOURCE_GROUP_NAME="demowebops"
REGION="canadacentral"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOG_WORKSPACE_NAME="aksLogsWorkspace"
AKS_CLUSTER_NAME="webopsaksclustors"
MYSQL_SERVER_NAME="mysqlwpsrvr5"
KEY_VAULT_NAME="<Your-KeyVault-Name>"

az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --workspace-name "$LOG_WORKSPACE_NAME" \
  --location "$REGION"

# 2. Get Log Analytics Workspace ID
LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --workspace-name "$LOG_WORKSPACE_NAME" \
  --query id -o tsv)

# 3. Enable monitoring addon for AKS
az aks enable-addons \
  --addons monitoring \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$AKS_CLUSTER_NAME" \
  --workspace-resource-id "$LOG_WORKSPACE_ID"

# 4. Enable monitoring for MySQL Flexible Server (Replacing SQL Server step)
MYSQL_RESOURCE_ID=$(az mysql flexible-server show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$MYSQL_SERVER_NAME" \
  --query id -o tsv)

az monitor diagnostic-settings create \
  --name "MySQLLogs" \
  --resource "$MYSQL_RESOURCE_ID" \
  --workspace "$LOG_WORKSPACE_ID" \
  --logs '[{"category": "QueryStoreRuntimeStatistics", "enabled": true}, {"category": "Connections", "enabled": true}]'

# 5. Enable Key Vault logging
KEY_VAULT_RESOURCE_ID=$(az keyvault show \
  --name "$KEY_VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query id -o tsv)

az monitor diagnostic-settings create \
  --name "KeyVaultLogs" \
  --resource "$KEY_VAULT_RESOURCE_ID" \
  --workspace "$LOG_WORKSPACE_ID" \
  --logs '[{"category": "AuditEvent", "enabled": true}]'

# 6. Enable Front Door logging (Placeholder)
# Uncomment and adjust once Azure Front Door is created
# FRONT_DOOR_RESOURCE_ID=$(az network front-door show \
#   --name "<Your-FrontDoor-Name>" \
#   --resource-group "$RESOURCE_GROUP_NAME" \
#   --query id -o tsv)
# az monitor diagnostic-settings create \
#   --name "FrontDoorLogs" \
#   --resource "$FRONT_DOOR_RESOURCE_ID" \
#   --workspace "$LOG_WORKSPACE_ID" \
#   --logs '[{"category": "FrontdoorAccessLog", "enabled": true}, {"category": "WAFLog", "enabled": true}]'
