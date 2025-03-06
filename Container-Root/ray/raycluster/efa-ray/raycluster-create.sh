#!/bin/bash

source create-container.sh
# Apply the Kubernetes configuration
CMD="envsubst < /aws-do-ray/Container-Root/ray/raycluster/efa-ray/raycluster-template-efa.yaml | kubectl apply -f -"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Cluster deployed successfully."
else
    echo "Error deploying cluster."
    exit 3
fi
