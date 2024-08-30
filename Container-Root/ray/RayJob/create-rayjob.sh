#!/bin/bash

# Apply the Kubernetes configuration
kubectl apply -f "rayjob-template.yaml"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Job deployed successfully."
    echo "Run 'kubectl get rayjob' to view the job status."
    echo "Run 'kubectl get raycluster' to view the cluster status."
    echo "Run 'kubectl get pods' to view cluster pods."
else
    echo "Error deploying RayJob "
    exit 3
fi