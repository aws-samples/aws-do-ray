#!/bin/bash

# Apply the Kubernetes configuration
kubectl apply -f "serve-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Service deployed successfully."
    echo "Run 'kubectl get rayservice' to view the serve status."
    echo "Run 'kubectl get raycluster' to view the cluster status."
    echo "Run 'kubectl get pods' to view cluster pods."
else
    echo "Error deploying RayService "
    exit 3
fi