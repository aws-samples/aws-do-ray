#!/bin/bash

# Apply the Kubernetes configuration
kubectl delete -f "serve-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Service deleted successfully."
    echo "Run 'kubectl get rayservice' to view the serve status."
else
    echo "Error deleting RayService "
    exit 3
fi