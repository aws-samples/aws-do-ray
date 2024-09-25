#!/bin/bash

source .env

export MODE=-it

echo "Testing ${IMAGE} ..."

CMD="docker container run ${RUN_OPTS} ${CONTAINER_NAME}-test ${MODE} --rm ${NETWORK} ${PORT_MAP} ${VOL_MAP} ${REGISTRY}${IMAGE}${TAG} sh -c 'for t in \$(ls /test*.sh); do echo Running test \$t; \$t; done;'"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

