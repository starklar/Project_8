###################################################################
# Setting up AKS with Ingress Controller, LoadBalancer, and HTTPS #
# Enabling SSL/TLS for secure traffic handling                    #
###################################################################

# Registered Domain in DNS Zones better to create in different resource group and update the DNS record
# Double check if it has been updated to Azure DNS
nslookup -type=SOA $WEBSITE_NAME 8.8.8.8
nslookup -type=NS $WEBSITE_NAME 8.8.8.8

# Verify the name of AKS created Node Resource Group and stored same in $AKSRESOURCEGROUPNAME variable
az aks show --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv

# Create a Static Public IP in Azure with Availability Zones for AKS
export MY_PUBLIC_STATIC_IP=$(az network public-ip create \
  --resource-group "$AKSRESOURCEGROUPNAME" \
  --location "$REGION" \
  --name "$MY_PUBLIC_IP_NAME" \
  --sku Standard \
  --allocation-method Static \
  --version IPv4 \
  --zone 1 2 3 \
  --query publicIp.ipAddress -o tsv)

# Print the value(for debugging or confirmation)
echo $MY_PUBLIC_STATIC_IP


# Install Helm if not
# Create a namespace for your ingress resources
kubectl create namespace ingress-basic

# Add the official stable repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Customizing the Chart Before Installing if needed
# helm show values ingress-nginx/ingress-nginx

# Install Helm ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.externalTrafficPolicy=Local \
    --set controller.service.loadBalancerIP=$MY_PUBLIC_STATIC_IP \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --wait --timeout 10m0s

# List Services with labels
kubectl get service -l app.kubernetes.io/name=ingress-nginx --namespace ingress-basic

# Output should be "404 Not Found from Nginx" upon accessing ingress IP from Browser

###############################################################################
# Setting up Kubernetes ExternalDNS to create Record Sets in Azure DNS from AKS
# Displaying the message that a Managed Service Identity (MSI) is being created
echo "Creating Managed Service Identity (MSI): $MSI_NAME"

# Create a Managed Service Identity (MSI) and store its ID
MSI_ID=$(az identity create \
  --name "$MSI_NAME" \
  --resource-group "$MY_RESOURCE_GROUP_NAME" \
  --location "$REGION" \
  --query 'id' -o tsv)

# Retrieve the Client ID of the newly created MSI
CLIENT_ID=$(az identity show \
  --name "$MSI_NAME" \
  --resource-group "$MY_RESOURCE_GROUP_NAME" \
  --query 'clientId' -o tsv)

##### IMPORTANT - Update Azure JSON File for External DNS #####
# To get Azure Tenant ID
az account show --query "tenantId"
# To get Azure Subscription ID
az account show --query "id"
# To get userAssignedIdentityID to update in azure.json
echo $CLIENT_ID

echo "{
  "tenantId": $(az account show --query "tenantId"),
  "subscriptionId": ${SUBSCRIPTION_ID},
  "resourceGroup": "dns-zones", 
  "useManagedIdentityExtension": true,
  "userAssignedIdentityID": ${CLIENT_ID}
}" > azure.json

# Get the managed identity principal ID
export PRINCIPAL_ID=$(az identity show --resource-group $MY_RESOURCE_GROUP_NAME --name $MSI_NAME --query 'principalId' --output tsv)
echo $PRINCIPAL_ID

# Assign Contributor role to the managed identity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MY_DNS_RESOURCE_GROUP_NAME"

# Do Manually if gives MSI error: #Open MSI -> group5-externaldns-access-to-dnszones -> Azure Role Assignments -> Add role assignment
#Scope: Resource group --> Subscription: <Your_Subscription> --> Resource group: dns-zones --> Role: Contributor --> Save

export MY_MANAGED_IDENTITY_ID=$(az identity show --resource-group $MY_RESOURCE_GROUP_NAME --name $MSI_NAME --query 'id' --output tsv)
echo $MY_MANAGED_IDENTITY_ID

# Retrieve VMSS Name
az vmss list --resource-group $AKSRESOURCEGROUPNAME --output table
AKS_VMSS_NAME=$(az vmss list --resource-group $AKSRESOURCEGROUPNAME --query "[?contains(name, 'aks-nodepool1')].name | [0]" -o tsv)
echo $AKS_VMSS_NAME

# Assign the managed identity to the AKS VMSS
az vmss identity assign \
  --name $AKS_VMSS_NAME \
  --resource-group $AKSRESOURCEGROUPNAME \
  --identities $MY_MANAGED_IDENTITY_ID

# Do Manually if gives error
#Go to Virtual Machine Scale Sets (VMSS) -> Open aks related VMSS (aks-agentpool-xxxxxxx-vmss)
#Go to Security -> Identity -> User assigned -> Add -> group5-externaldns-access-to-dnszones


# create azure-config-file Secrets for External DNS deployment
# Navigate to the Path to azure.json here
kubectl create secret generic azure-config-file --from-file=azure.json=$(pwd)/azure.json

###########################################################################
# Configuring SSL on Ingress and issuing SSL certificate with Let's Encrypt
# Label the ingress-basic namespace to disable resource validation
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true --overwrite

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io --force-update

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager \
  --namespace ingress-basic \
  --version v1.13.3 \
  --set installCRDs=true
