#!/bin/bash

source ./env_vars

# Function to get cloud deployment ID from cloud name
get_cloud_deployment_id() {
    local CLOUD_NAME=$1
    local CLOUD_INFO
    local DEPLOYMENT_ID

    CLOUD_INFO=$(anyscale cloud config get --name "$CLOUD_NAME")
    if [ $? -ne 0 ]; then
        echo "Error getting cloud configuration for $CLOUD_NAME"
        exit 1
    fi

    DEPLOYMENT_ID=$(echo "$CLOUD_INFO" | grep "^cloud_deployment_id: " | awk '{print $2}')
    if [ -z "$DEPLOYMENT_ID" ]; then
        echo "Could not find cloud deployment ID"
        exit 1
    fi

    echo "$DEPLOYMENT_ID"
}


echo "Getting cloud deployment ID for: $CLOUD_NAME"
CLOUD_DEPLOYMENT_ID=$(get_cloud_deployment_id "$CLOUD_NAME")
echo "Cloud Deployment ID: $CLOUD_DEPLOYMENT_ID"

# Deploy Anyscale operator
helm upgrade --install anyscale-operator anyscale/anyscale-operator \
    --set-string cloudDeploymentId=${CLOUD_DEPLOYMENT_ID} \
    --set-string cloudProvider=aws \
    --set-string region=${AWS_REGION} \
    --set-string workloadServiceAccountName=anyscale-operator \
    --namespace anyscale


kubectl patch deployment anyscale-operator -n anyscale --patch "$(cat patch.yaml)"
