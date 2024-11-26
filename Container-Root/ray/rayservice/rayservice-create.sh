#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No model name provided."
    echo "Usage: ./rayservice-create.sh <ModelName>"
    echo "Available model names: detr, mobilenet, stable-diffusion"
    echo ""
    exit 1
fi

# Set the model name from the argument
MODEL_NAME=$1

# Convert the model name to lowercase for consistency
MODEL_NAME=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

# Create service name from model name
SERVICE_NAME=$(echo "${MODEL_NAME}-serve-svc" | tr '_' '-')


CMD="kubectl apply -f ${MODEL_NAME}/rayservice.${MODEL_NAME}.yaml"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"


# Check if the kubectl apply command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the rayservice configuration for ${MODEL_NAME}."
    exit 1
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "Service deployed successfully for model: ${MODEL_NAME}."
    echo ""
else
    echo "Error deploying RayService for model: ${MODEL_NAME}"
    exit 3
fi

echo "Waiting for query service... this service is created after the Ray Serve applications are ready and running so this process may take approximately 1 minute after the pods are running. Please hang tight"
SVC_CNT=0
while [ "$SVC_CNT" == "0" ]; do 
	sleep 2
	SVC_CNT=$(kubectl get svc | grep ${SERVICE_NAME} | wc -l)
done
echo ""
echo "Forwarding the port for Stable Diffusion Query"
echo ""
kubectl port-forward svc/${SERVICE_NAME} 8000 > /dev/null 2>&1 &

if [ $? -eq 0 ]; then
    echo "Query is ready..."
    echo ""
    echo "Please run './rayservice-test.sh ${MODEL_NAME}' to send a request to the model"
    echo ""
    echo "If you would like to change the query, please visit ${MODEL_NAME}_req.py in ${MODEL_NAME} folder and update appropriate variables"
    echo ""
else
    echo "Failed to port forward query..."
    echo ""
    echo "Issue may be service "svc/${SERCICE_NAME}" is not ready... please run 'kubectl get svc' to double check."
    echo "If it becomes ready, please run 'kubectl port-forward svc/${SERVICE_NAME} 8000'"
    echo ""
fi

echo "Run './rayservice-status.sh' or ' to view the serve status."
echo "Run 'kubectl get pods' or 'kgp' to view cluster pods."
