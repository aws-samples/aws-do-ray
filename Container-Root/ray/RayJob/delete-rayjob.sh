#!/bin/bash

# Apply the Kubernetes configuration
kubectl delete -f "rayjob-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "RayJob deleted successfully."
else
    echo "Error deleting RayJob."
    exit 3
fi