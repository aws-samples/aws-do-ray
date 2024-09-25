#!/bin/bash

# Apply the Kubernetes configuration
CMD="kubectl apply -f raycluster-template.yaml"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Cluster deployed successfully."
else
    echo "Error deploying cluster."
    exit 3
fi

