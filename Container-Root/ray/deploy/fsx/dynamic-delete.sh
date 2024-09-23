#!/bin/bash
echo "In kuberay namespace..."

echo "Deleting dynamic-pvc.yaml"
kubectl delete -f /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-pvc.yaml -n kuberay

echo "Deleting dynamic-storageclass.yaml"
# kubectl apply -f dynamic-storageclass.yaml -n kuberay
envsubst < /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-storageclass.yaml | kubectl delete -n kuberay  -f -

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim -n kuberay
