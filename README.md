To run, open Cloud CLI (or connecting to Azure through your own terminal should work) and either copy paste
the commands from or upload and run the project_setup.sh file.

Note that you may want to change some of the variables values before you run (ex. $MY_RESOURCE_GROUP_NAME)
so that people do not get confused if people happen to be working at the same time.

Try to keep variables at the top of the file. And also please make new ones as they come up.



## How to test the key vault connection?
Clone the connection test deck from ms azure
```bash
git clone https://github.com/Azure-Samples/serviceconnector-aks-samples.git
```
change directory into serviceconnector-aks-samples/azure-keyvault-csi-provider
```
cd serviceconnector-aks-samples/azure-keyvault-csi-provider
```
target file to be modified: secret_provider_class.yaml
```yaml
{
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: sc-demo-keyvault-csi
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"                        # Set to true for using managed identity
    userAssignedIdentityID: <AZURE_KEYVAULT_CLIENTID>   # Set the clientID of the user-assigned managed identity to use
    keyvaultName: <AZURE_KEYVAULT_NAME>                 # Set to the name of your key vault
    objects:  |
      array:
        - |
          objectName: <KEYVAULT_SECRET_NAME>            # keyvault secret name
          objectType: secret
    tenantId: <AZURE_KEYVAULT_TENANTID>                 # The tenant ID of the key vault
}
```

Replace "AZURE_KEYVAULT_NAME" with the name of the key vault you created and connected.

Replace "AZURE_KEYVAULT_TENANTID" with The directory ID of the aks key vault, which is showing in the overview of your key vault.

Replace "AZURE_KEYVAULT_CLIENTID" with identity client ID of the azureKeyvaultSecretsProvider addon, you can find it aks keyvault managed identity which created by the system

Replace "KEYVAULT_SECRET_NAME" with the key vault secret you created.

```bash
  kubectl apply -f secret_provider_class.yaml
  kubectl apply -f pod.yaml
  kubectl get pod/sc-demo-keyvault-csi
  kubectl exec sc-demo-keyvault-csi -- ls /mnt/secrets-store/ #if connected, it will show your secret name
  kubectl exec sc-demo-keyvault-csi -- cat /mnt/secrets-store/AKSClusterSecret ##if connected, it will show your secret value
```