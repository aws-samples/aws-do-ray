#!/bin/bash

source .env

CMD="docker image push ${REGISTRY}${IMAGE}${TAG}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

