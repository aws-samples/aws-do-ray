#!/bin/bash
# Remove kuberay Manifests
NS_COUNT=$(kubectl get namespace kuberay | grep kuberay | wc -l)
if [ "$NS_COUNT" == "1" ]; then
    echo "Removing Kuberay Operator..."
    helm uninstall kuberay-operator --namespace kuberay
    echo "Deleting Kuberay namespace..."
    kubectl delete namespace kuberay
else
    echo "Namespace kuberay does not exist, skipping..."
fi


# Now creating FSX for Lustre
echo "Deleting FSX For Lustre Cluster..."
echo "Deleting FSX Dependences..."
./deploy/fsx/remove.sh

echo "Deleting dynamically provisioning FSX For Lustre Cluster... this may take a few minutes"
./deploy/fsx/dynamic-delete.sh
