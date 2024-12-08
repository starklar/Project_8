#########################
# !!! CREATING ACR !!!! #
#########################

# Step 1: Create Azure Container Registry (ACR) with Premium SKU
# The Premium SKU is used to enable features like geo-replication and private endpoints.
az acr create --resource-group $MY_RESOURCE_GROUP_NAME --name $ACR_NAME --sku Premium

# Step 2: Import Docker Image from Docker Hub into ACR
# The image will be stored in ACR for use within AKS clusters.
az acr import --name $ACR_NAME --source docker.io/$DOCKER_HUB_IMAGE_NAME --image $DOCKER_HUB_IMAGE_NAME --resource-group $MY_RESOURCE_GROUP_NAME