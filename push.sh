#!/bin/bash

source .env

# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"${IMAGE}\" | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
	aws ecr create-repository --repository-name ${IMAGE}
fi

# Login to registry
./login.sh

CMD="docker image push ${REGISTRY}${IMAGE}${TAG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image tag ${REGISTRY}${IMAGE}${TAG} ${REGISTRY}${IMAGE}:latest"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image push ${REGISTRY}${IMAGE}:latest"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

