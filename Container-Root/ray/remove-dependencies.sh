#!/bin/bash

# Delete dynamic volumes
echo "Deleting dynamically provisioning FSX For Lustre Cluster... this may take a few minutes"
./deploy/fsx/dynamic-delete.sh

# Delete FSX for Lustre dependencies
echo "Deleting FSX Dependences..."
./deploy/fsx/remove.sh

# Remove KubeRay
NS_COUNT=$(kubectl get namespace kuberay | grep kuberay | wc -l)
if [ "$NS_COUNT" == "1" ]; then
    echo "Removing Kuberay Operator..."
    helm uninstall kuberay-operator --namespace kuberay
    echo "Deleting Kuberay namespace..."
    kubectl delete namespace kuberay
else
    echo "Namespace kuberay does not exist, skipping..."
fi

