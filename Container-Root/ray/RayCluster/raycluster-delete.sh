#!/bin/bash

# Apply the Kubernetes configuration
kubectl delete -f "raycluster-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Cluster deleted successfully."
else
    echo "Error deleting cluster."
    exit 3
fi




