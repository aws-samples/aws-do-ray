#!/bin/bash

source ./env_vars

if [ -z "$ANYSCALE_CLOUD_NAME" ]; then
    echo "Anyscale Cloud name cannot be empty"
    exit 1
fi

echo "Registering Anyscale cloud: $ANYSCALE_CLOUD_NAME"
echo "-------------------------"


# Get the PVC name and associated PV name
echo "Retrieving Elastic File System..."

if [ -f ./efs_env.sh ]; then
    source ./efs_env.sh
    echo "Using EFS_ID from env file: $EFS_ID"
else
    echo "EFS_ID not found. Please enter EFS ID:"
    read EFS_ID
    exit 1
fi

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

echo "Adding S3 read/write permissions to Node Role for Anyscale operator"
cat > anyscale-s3-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::*/*",
                "arn:aws:s3:::*"
            ]
        }
    ]
}
EOF
aws iam create-policy --policy-name anyscale --policy-document file://anyscale-s3-policy.json
ACCOUNT_ID=$(echo $ROLE | cut -d':' -f5)
aws iam attach-role-policy \
    --role-name $ROLE \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/anyscale


anyscale cloud register \
  --name ${ANYSCALE_CLOUD_NAME} \
  --provider aws \
  --region ${AWS_REGION} \
  --compute-stack k8s \
  --kubernetes-zones ${AWS_AZ} \
  --anyscale-operator-iam-identity ${ROLE} \
  --cloud-storage-bucket-name ${S3_BUCKET} \
  --file-storage-id ${EFS_ID}

echo consent | anyscale cloud config update ${ANYSCALE_CLOUD_NAME} \
  --enable-log-ingestion
