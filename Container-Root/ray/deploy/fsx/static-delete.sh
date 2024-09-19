#!/bin/bash
echo "In kuberay namespace..."

echo "Deleting static-storageclass.yaml"
# kubectl apply -f static-storageclass.yaml -n kuberay
envsubst < static-storageclass.yaml | kubectl delete -n kuberay  -f -


echo "Deleting static-pv.yaml"
# kubectl apply -f static-pv.yaml -n kuberay
envsubst < static-pv.yaml | kubectl delete -n kuberay  -f -


echo "Deleting static-pvc.yaml"
kubectl delete -f static-pvc.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim -n kuberay