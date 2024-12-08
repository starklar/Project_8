#########################
# !!! CREATING AKS !!!! #
#########################

# Register AKS Provider
az provider register --namespace Microsoft.ContainerService

# Creatig Workspace for monitoring
az monitor log-analytics workspace create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --workspace-name $MY_MONITORING_WORKSPACE_NAME \
  --location $REGION

# Adding a 30-second delay before the next step
echo "Waiting for 30 seconds to let the previous step complete..."
sleep 30

# Create AKS Cluster
az aks create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $MY_AKS_CLUSTER_NAME \
  --enable-cluster-autoscaler \
  --location $REGION \
  --node-count 1 \
  --min-count 1 \
  --max-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --zones 1 2 3 \
  --vnet-subnet-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MY_RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$MY_VNET_NAME/subnets/$AKS_SUBNET_NAME" \
  --attach-acr $ACR_NAME \
  --enable-addons monitoring \
  --enable-addons azure-keyvault-secrets-provider \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --network-plugin azure \
  --no-ssh-key

# Get AKS Cluster Credenials
az aks get-credentials --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_AKS_CLUSTER_NAME

# Verify that each node in your cluster's node pool has a Secrets Store CSI Driver pod and a Secrets Store Provider Azure pod running
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

