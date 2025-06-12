#!/bin/bash

source ./env_vars

# ==== Create EFS File System ====

echo "Creating EFS file system..."

echo "Retrieving Subnet ID..."
SUBNET_ID=$(aws sagemaker describe-cluster \
    --cluster-name $AWS_EKS_HYPERPOD_CLUSTER \
    --region $AWS_REGION \
    --query 'VpcConfig.Subnets' \
    --output text)
echo "Subnet ID: $SUBNET_ID"

echo "Retrieving VPC ID..."
VPC_ID=$(aws ec2 describe-subnets \
  --subnet-ids ${SUBNET_ID} \
  --query "Subnets[0].VpcId" \
  --output text)
echo "VPC ID: $VPC_ID"


echo "Retrieving Security Group ID..."
SECURITY_GROUP_ID=$(aws sagemaker describe-cluster \
	--cluster-name $AWS_EKS_HYPERPOD_CLUSTER \
	--region $AWS_REGION \
	--query 'VpcConfig.SecurityGroupIds[0]' \
	--output text)
echo "Security group ID: $SECURITY_GROUP_ID"


EFS_ID=$(aws efs create-file-system \
  --region $AWS_REGION \
  --encrypted \
  --performance-mode "$PERFORMANCE_MODE" \
  --throughput-mode "$THROUGHPUT_MODE" \
  --tags Key=Name,Value="$EFS_NAME" \
  --query 'FileSystemId' \
  --output text)

echo "EFS created with ID: $EFS_ID"

# ==== Wait until EFS is available ====
echo "Waiting for EFS file system $EFS_ID in region $AWS_REGION to become available..."

MAX_RETRIES=30
RETRY_INTERVAL=10  # seconds

for ((i=1; i<=MAX_RETRIES; i++)); do
  STATUS=$(aws efs describe-file-systems \
    --file-system-id "$EFS_ID" \
    --region ${AWS_REGION} \
    --query "FileSystems[0].LifeCycleState" \
    --output text 2>/dev/null)

  if [[ "$STATUS" == "available" ]]; then
    echo "✅ EFS $EFS_ID is now available."
    break
  fi

  echo "[$i/$MAX_RETRIES] EFS not ready yet (status: $STATUS). Retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done

# ==== Create Mount Target ====
echo "Creating mount target in subnet $SUBNET_ID..."
aws efs create-mount-target \
  --region $AWS_REGION \
  --file-system-id "$EFS_ID" \
  --subnet-id "$SUBNET_ID" \
  --security-groups "$SECURITY_GROUP_ID"

echo "Mount target created for EFS $EFS_ID"

echo "export EFS_ID=$EFS_ID" > ./efs_env.sh

# ==== Output File System Info ====
echo ""
echo "EFS File System Details:"
aws efs describe-file-systems --file-system-id "$EFS_ID" --region $AWS_REGION

