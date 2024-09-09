#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo "Error: No model name provided."
    echo "Usage: ./rayjob-create.sh <Job>"
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

# Apply the appropriate YAML file based on the model name
if [ "$MODEL_NAME" == "batch-inference" ]; then
    kubectl apply -f batch-inference/ray-job.batch-inference.yaml -n kuberay
elif [ "$MODEL_NAME" == "test-counter" ]; then
    kubectl apply -f test-counter/ray-job.test-counter.yaml -n kuberay
else
    echo "Error: Invalid model name. Available options are: test-counter or batch-inference."
    exit 2
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "RayJob deployed successfully for model: $MODEL_NAME."
    echo "Run 'kubectl get rayjob --namespace kuberay' to view the job status."
    echo "Run 'kubectl get pods --namespace kuberay' to view job pods."
else
    echo "Error deploying RayJob for model: $MODEL_NAME"
    exit 3
fi

