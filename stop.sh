#!/bin/bash

source .env

CMD="docker container rm -f ${CONTAINER}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

