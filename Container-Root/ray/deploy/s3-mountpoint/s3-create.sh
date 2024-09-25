#!/bin/bash

echo "Applying pv-s3.yaml"

envsubst < pv-s3.yaml | kubectl apply -f -

echo "Applying pvc-s3.yaml"
kubectl apply -f pvc-s3.yaml

echo "Describing pvc s3-claim"
kubectl describe pvc s3-claim