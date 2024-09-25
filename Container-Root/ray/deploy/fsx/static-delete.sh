#!/bin/bash

echo "Deleting static-storageclass.yaml"

envsubst < static-storageclass.yaml | kubectl delete  -f -


echo "Deleting static-pv.yaml"
envsubst < static-pv.yaml | kubectl delete  -f -


echo "Deleting static-pvc.yaml"
kubectl delete -f static-pvc.yaml

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim