#!/bin/bash
echo "In kuberay namespace..."

echo "Deleting dynamic-storageclass.yaml"
# kubectl apply -f dynamic-storageclass.yaml -n kuberay
envsubst < dynamic-storageclass.yaml | kubectl delete -n kuberay  -f -

echo "Deleting dynamic-pvc.yaml"
kubectl delete -f dynamic-pvc.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim