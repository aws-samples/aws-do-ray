#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo "Error: No model name provided."
    echo "Usage: ./create-serve.sh <ModelName>"
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

# Apply the appropriate YAML file based on the model name
if [ "$MODEL_NAME_LOWER" == "mobilenet" ]; then
    kubectl delete -f MobileNet/ray-service.mobilenet.yaml -n kuberay
elif [ "$MODEL_NAME_LOWER" == "detr" ]; then
    kubectl delete -f DETR/ray-service.detr.yaml -n kuberay
elif [ "$MODEL_NAME_LOWER" == "stablediffusion" ]; then
    kubectl delete -f StableDiffusion/ray-service.stable-diffusion.yaml -n kuberay
else
    echo "Error: Invalid model name. Available options are: MobileNet, DETR, StableDiffusion."
    exit 2
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Service deleted successfully for model: $MODEL_NAME."
    echo "Run 'kubectl get rayservice --namespace kuberay' to view the serve status."
    echo "Run 'kubectl get raycluster --namespace kuberay' to view the cluster status."
    echo "Run 'kubectl get pods --namespace kuberay' to view cluster pods."
    echo "View RayService README for next steps..."
else
    echo "Error deleting RayService for model: $MODEL_NAME"
    exit 3
fi