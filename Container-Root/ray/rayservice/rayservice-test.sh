#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No model name provided."
    echo "Usage: $0 <ModelName>"
    echo "Available model names: "
    echo ""
    ./rayservice-status.sh
    echo ""
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')


CMD="python3 ${MODEL_NAME}/${MODEL_NAME}_req.py"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

