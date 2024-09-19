#!/bin/bash
echo "In kuberay namespace..."

echo "Applying dynamic-storageclass.yaml"
# kubectl apply -f dynamic-storageclass.yaml -n kuberay
envsubst < dynamic-storageclass.yaml | kubectl apply -n kuberay  -f -


echo "Applying dynamic-pvc.yaml"
kubectl apply -f dynamic-pvc.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim



