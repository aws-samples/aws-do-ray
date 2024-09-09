#!/bin/bash
echo "In kuberay namespace..."

echo "Deleting static-storageclass.yaml"
kubectl delete -f static-storageclass.yaml -n kuberay

echo "Deleting static-pvc.yaml"
kubectl delete -f static-pvc.yaml -n kuberay

echo "Deleting static-pv.yaml"
kubectl delete -f static-pv.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim -n kuberay