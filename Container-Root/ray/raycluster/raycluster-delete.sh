#!/bin/bash

# Apply the Kubernetes configuration
CMD="kubectl delete -f raycluster-template.yaml"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Cluster deleted successfully."
else
    echo "Error deleting cluster."
    exit 3
fi

