#!/bin/bash

# Apply the Kubernetes configuration
kubectl apply -f "raycluster-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Cluster deployed successfully."
    echo "Run 'kubectl get raycluster' to view the cluster status."
    echo "Run 'kubectl get pods' to view the cluster pods."
else
    echo "Error deploying cluster."
    exit 3
fi




