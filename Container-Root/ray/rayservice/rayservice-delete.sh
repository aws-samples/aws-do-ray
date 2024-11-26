#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No model name provided."
    echo "Usage: ./rayservice-delete.sh <ModelName>"
    echo "Services that can be deleted: "
    echo ""
    ./rayservice-status.sh
    echo ""
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

CMD="kubectl delete -f ${MODEL_NAME}/rayservice.${MODEL_NAME}.yaml"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

# Check if the kubectl apply command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to delete the rayservice for ${MODEL_NAME}."
    exit 1
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Service deleted successfully for model: $MODEL_NAME."
    echo "Run './rayservice-status.sh' to view the serve status."
    echo "Run 'kgp' to view cluster pods."
    echo ""
else
    echo "Error deleting RayService for model: $MODEL_NAME"
    echo "Services that can be deleted: "
    echo ""
    ./rayservice-status.sh
    echo ""
    exit 3
fi

echo "Killing requesting process if another service was previously deployed..."
pid=$(lsof -i :8000 | awk 'NR==2 {print $2}')
kill ${pid}
