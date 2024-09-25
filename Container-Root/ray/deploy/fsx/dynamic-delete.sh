#!/bin/bash

echo "Deleting dynamic-pvc.yaml"
kubectl delete -f /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-pvc.yaml

echo "Deleting dynamic-storageclass.yaml"

envsubst < /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-storageclass.yaml | kubectl delete  -f -

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim
