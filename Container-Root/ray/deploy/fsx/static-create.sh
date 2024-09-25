#!/bin/bash

echo "Applying static-storageclass.yaml"

envsubst < static-storageclass.yaml | kubectl apply  -f -


echo "Applying static-pv.yaml"

envsubst < static-pv.yaml | kubectl apply  -f -


echo "Applying static-pvc.yaml"
kubectl apply -f static-pvc.yaml

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim