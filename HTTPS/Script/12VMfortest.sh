#############################################
# !!! CREATING VM FOR TESTING PURPOSE !!!   #
#############################################

# # Create the VM for testing the connection between private endpoing and mysql server
az vm create \
  -g $MY_RESOURCE_GROUP_NAME \
  -n $MY_VM_NAME \
  --image Win2019Datacenter \
  --location $REGION \
  --vnet-name $MY_VNET_NAME \
  --subnet $VM_SUBNET_NAME \
  --admin-username $MY_VM_USERNAME \
  --admin-password $MY_VM_ADMIN_PW \
  --authentication-type password \
  --size Standard_B2s \
  --public-ip-sku Standard \
  --no-wait

# Get VM public ip address
export MY_VM_PUBLIC_IP="$(az vm list-ip-addresses -g $MY_RESOURCE_GROUP_NAME -n $MY_VM_NAME --query [].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)"
echo $MY_VM_PUBLIC_IP
