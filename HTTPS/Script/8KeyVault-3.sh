#####################################################################
# !!! CREATE SERVICE ACCOUNT IN AKS, ASSIGN WITH MANAGED IDENTITY !!!
#####################################################################

# Export UAMI client ID, KV's Directory ID, AKS OIDC Issuer and KeyVault Scope
export KV_USER_ASSIGNED_CLIENT_ID="$(az identity show -g $MY_RESOURCE_GROUP_NAME --name $UAMI --query 'clientId' -o tsv)"
export KV_IDENTITY_TENANT=$(az aks show --name $MY_AKS_CLUSTER_NAME --resource-group $MY_RESOURCE_GROUP_NAME --query identity.tenantId -o tsv)
export AKS_OIDC_ISSUER="$(az aks show --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_AKS_CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"
export KV_FEDERATED_IDENTITY_NAME="aksfederatedidentity"
export KV_SERVICE_ACCOUNT_NAME="workload-identity-sa"
export KV_SERVICE_ACCOUNT_NAMESPACE="default"

# Cerify if variables storing correct information
echo $KV_USER_ASSIGNED_CLIENT_ID   #Client ID of newly created managed Identity UAMI
echo $KV_IDENTITY_TENANT #Directory ID of KeyVault and same is tenand ID of AKS Clustor
echo $AKS_OIDC_ISSUER


# Create Service Account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${KV_USER_ASSIGNED_CLIENT_ID}
  name: ${KV_SERVICE_ACCOUNT_NAME}
  namespace: ${KV_SERVICE_ACCOUNT_NAMESPACE}
EOF

# OR
# envsubst < 5serviceaccount.yaml | kubectl apply -f -

kubectl get serviceaccounts -n default

# Setup Federation - Connecting Service Account to Managed Identity Created for Key Vault
az identity federated-credential create --name $KV_FEDERATED_IDENTITY_NAME --identity-name $UAMI --resource-group $MY_RESOURCE_GROUP_NAME --issuer ${AKS_OIDC_ISSUER} --subject system:serviceaccount:${KV_SERVICE_ACCOUNT_NAMESPACE}:${KV_SERVICE_ACCOUNT_NAME}

# Testing and Troubleshooting
# kubectl get pods -l app=mywpapp-webops
# kubectl exec -it ushipwpbywebops-deployment-f585d9cc8-fw4kr -- env | grep WORDPRESS
# kubectl exec <your-pod-id> -- ls /mnt/secrets-store/