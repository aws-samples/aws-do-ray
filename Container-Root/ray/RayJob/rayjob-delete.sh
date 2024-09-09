#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo "Error: No model name provided."
    echo "Usage: ./rayjob-delete.sh <Job>"
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

# Apply the appropriate YAML file based on the model name
if [ "$MODEL_NAME" == "test-counter" ]; then
    kubectl delete -f test-counter/ray-job.test-counter.yaml -n kuberay
else
    echo "Error: Invalid model name. Available options are: test-counter."
    exit 2
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "RayJob deleted successfully for model: $MODEL_NAME."
    echo "Run 'kubectl get rayjob --namespace kuberay' to view the job status."
else
    echo "Error deleting RayJob for model: $MODEL_NAME"
    exit 3
fi

