#!/bin/bash
echo "In kuberay namespace..."

echo "Applying static-storageclass.yaml"
# kubectl apply -f static-storageclass.yaml -n kuberay
envsubst < static-storageclass.yaml | kubectl apply -n kuberay  -f -


echo "Applying static-pv.yaml"
# kubectl apply -f static-pv.yaml -n kuberay
envsubst < static-pv.yaml | kubectl apply -n kuberay  -f -


echo "Applying static-pvc.yaml"
kubectl apply -f static-pvc.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim -n kuberay