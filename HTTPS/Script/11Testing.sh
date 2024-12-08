# !!!! Verification Steps !!!!
# Verify all deployments, pods, svc, sc, pv, pvc, secrets
kubectl get deployments -o wide
kubectl get pods
kubectl get svc
kubectl get sc
kubectl get pv
kubectl get pvc
kubectl get secrets
kubectl get ingress
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
nslookup ushipideliver.ca


kubectl delete -f 9deployment.yaml
kubectl delete -f 6secretprovider.yaml
kubectl delete secretproviderclass azure-kvname-wi

# To get into pods to check if mysql certificate and wp-config file provided is present
kubectl exec -it ushipwpbywebops-deployment-xxxxxpodidxxxxx-xxxx -- /bin/bash
# Install nano function to edit the file if needed
apt-get update && apt-get install nano

# List all deployments inside ingress-basic and verify cert-manager pods, cert-manager svc and ingress controller
kubectl get all -n ingress-basic
kubectl -n ingress-basic logs -f cert-manager-7dd948954-ctdb7 -n ingress-basic
kubectl get certificates -A    #Ready status should be true once certificate get created
kubectl cert-manager renew ushipideliver.ca-secret-prod