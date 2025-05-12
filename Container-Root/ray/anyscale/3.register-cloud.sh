#!/bin/bash

source ./env_vars

if [ -z "$CLOUD_NAME" ]; then
    echo "Anyscale Cloud name cannot be empty"
    exit 1
fi

echo "Registering Anyscale cloud: $CLOUD_NAME"
echo "-------------------------"


# Get the PVC name and associated PV name
echo "Retrieving Elastic File System..."

echo "Please enter EFS ID: "
read EFS_ID

if [ -z "$EFS_ID" ]; then
    echo "Could not find EFS file system ID"
    exit 1
fi

echo "EFS ID: $EFS_ID"

echo "Retrieving S3 Bucket..."

S3_BUCKET=$(aws sagemaker describe-cluster \
    --cluster-name $AWS_EKS_HYPERPOD_CLUSTER \
    --region $AWS_REGION \
    --query 'InstanceGroups[0].LifeCycleConfig.SourceS3Uri' \
    --output text)

echo "S3 Bucket: $S3_BUCKET"

echo "Retrieving Node Role for Anyscale operator..."
ROLE=$(aws sagemaker describe-cluster \
    --cluster-name "$AWS_EKS_HYPERPOD_CLUSTER" \
    --region ${AWS_REGION} \
    --query 'InstanceGroups[0].ExecutionRole' \
    --output text)
    
    # Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Role ARN: $ROLE"
else
    echo "Error retrieving cluster execution role"
    exit 1
fi

anyscale cloud register \
  --name ${CLOUD_NAME} \
  --provider aws \
  --region ${AWS_REGION} \
  --compute-stack k8s \
  --kubernetes-zones ${AWS_AZ} \
  --anyscale-operator-iam-identity ${ROLE} \
  --cloud-storage-bucket-name ${S3_BUCKET} \
  --file-storage-id ${EFS_ID}

echo consent | anyscale cloud config update ${CLOUD_NAME} \
  --enable-log-ingestion
