#!/bin/bash
echo "In kuberay namespace..."

echo "Applying pv-s3.yaml"
# kubectl apply -f pv-s3.yaml -n kuberay
envsubst < pv-s3.yaml | kubectl apply -n kuberay -f -

echo "Applying pvc-s3.yaml"
kubectl apply -f pvc-s3.yaml -n kuberay

echo "Describing pvc s3-claim"
kubectl describe pvc s3-claim -n kuberay