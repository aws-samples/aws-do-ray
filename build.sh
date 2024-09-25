#!/bin/bash

source .env

echo "aws-do-ray shell $VERSION" > Container-Root/version.txt

# Build Docker image
CMD="docker image build --platform linux/amd64 ${BUILD_OPTS} -t ${REGISTRY}${IMAGE}${TAG} ."

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

