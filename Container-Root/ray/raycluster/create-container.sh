#!/bin/bash

export AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export REGISTRY=${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/

echo "This process may take 10-15 minutes to complete..."

echo "Building image..."

docker build --platform linux/amd64 -t ${REGISTRY}aws-ray-custom:latest .

# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"aws-ray-custom\" | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
    aws ecr create-repository --repository-name aws-ray-custom
fi

# Login to registry
echo "Logging in to $REGISTRY ..."
aws ecr get-login-password --region $AWS_REGION| docker login --username AWS --password-stdin $REGISTRY

echo "Pushing image to $REGISTRY ..."

# Push image to registry
docker image push ${REGISTRY}aws-ray-custom:latest

