#!/bin/bash

set -e

source /aws-do-ray/.env

# FSX CONFIGURATION

echo "Getting Subnet ID"
# SUBNET_ID
if [ "$CLUSTER_TYPE" == "eks" ]; then
    # Get all subnets associated with the EKS cluster
    ALL_SUBNET_IDS=$(aws eks describe-cluster --name $AWS_EKS_CLUSTER --region $AWS_REGION --query 'cluster.resourcesVpcConfig.subnetIds[]' --output text)
    # Filter for private subnets by checking if MapPublicIpOnLaunch is false and return only the first one
    SUBNET_ID=$(aws ec2 describe-subnets --subnet-ids $(echo $ALL_SUBNET_IDS) --region $AWS_REGION --query "Subnets[?MapPublicIpOnLaunch == \`false\`].SubnetId | [0]" --output text)
elif [ "$CLUSTER_TYPE" == "hyperpod" ]; then
    #if hyperpod
    SUBNET_ID=$(aws sagemaker describe-cluster --cluster-name $AWS_EKS_HYPERPOD_CLUSTER --region $AWS_REGION --query 'VpcConfig.Subnets' --output text)
else
    echo "Unknown CLUSTER value: $CLUSTER, unable to retrieve Subnet ID"
    exit 1
fi

export SUBNET_ID=$SUBNET_ID
echo "SUBNET_ID: "
echo $SUBNET_ID


echo "Getting Security Group ID"
SECURITYGROUP_ID_EKS=$(aws eks describe-cluster --name $AWS_EKS_CLUSTER --region $AWS_REGION --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
if [ "$CLUSTER_TYPE" == "hyperpod" ]; then
    # If CLUSTER is 'hyperpod', get the first security group ID
    SECURITYGROUP_ID_HYPERPOD=$(aws sagemaker describe-cluster --cluster-name aws-do-hyperpod-eks-smhp --region $AWS_REGION --query 'VpcConfig.SecurityGroupIds' --output text)
    SECURITYGROUP_ID="$SECURITYGROUP_ID_EKS,$SECURITYGROUP_ID_HYPERPOD"
    aws ec2 authorize-security-group-ingress \
      --group-id $SECURITYGROUP_ID_HYPERPOD \
      --protocol all \
      --port all \
      --source-group $SECURITYGROUP_ID_HYPERPOD 2>&1 | grep -v "InvalidPermission.Duplicate"
else
    SECURITYGROUP_ID=$SECURITYGROUP_ID_EKS
fi

# allows all inbound traffic sourced from itself
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITYGROUP_ID_EKS \
  --protocol all \
  --port all \
  --source-group $SECURITYGROUP_ID_EKS 2>&1 | grep -v "InvalidPermission.Duplicate"


export SECURITYGROUP_ID=$SECURITYGROUP_ID
echo "SECURITYGROUP_ID: "
echo $SECURITYGROUP_ID


echo "In kuberay namespace..."

echo "Applying dynamic-storageclass.yaml"
# kubectl apply -f dynamic-storageclass.yaml -n kuberay
envsubst < /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-storageclass.yaml | kubectl apply -n kuberay  -f -


echo "Applying dynamic-pvc.yaml"
kubectl apply -f /aws-do-ray/Container-Root/ray/deploy/fsx/dynamic-pvc.yaml -n kuberay

echo "Describing pvc fsx-claim"
kubectl describe pvc fsx-claim -n kuberay



