#!/bin/bash

source ../../../../.env

echo $REGISTRY
export IMAGE=cron-job

# Build Docker image
CMD="docker image build ${BUILD_OPTS} -t ${REGISTRY}${IMAGE}${TAG} ."

if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"${IMAGE}\" | wc -l | tr -d ' ')
if [ "$REGISTRY_COUNT" == "0" ]; then
	CMD="aws ecr create-repository --repository-name ${IMAGE}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

# Login to registry
# Login to container registry
echo "Logging in to $REGISTRY ..."
CMD="aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"



CMD="docker image push ${REGISTRY}${IMAGE}${TAG}"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image tag ${REGISTRY}${IMAGE}${TAG} ${REGISTRY}${IMAGE}:latest"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image push ${REGISTRY}${IMAGE}:latest"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

