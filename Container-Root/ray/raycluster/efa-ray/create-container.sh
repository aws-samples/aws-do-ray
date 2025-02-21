#!/bin/bash

export AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export REGISTRY=${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/

docker build --platform linux/amd64 -t ${REGISTRY}ray-efa:latest .

# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"ray-efa\" | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
    aws ecr create-repository --repository-name ray-efa
fi

# Login to registry
echo "Logging in to $REGISTRY ..."
aws ecr get-login-password --region $AWS_REGION| docker login --username AWS --password-stdin $REGISTRY

# Push image to registry
docker image push ${REGISTRY}ray-efa:latest


