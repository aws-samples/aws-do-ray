#!/bin/bash

source .env

CMD="docker ps -a | grep ${CONTAINER}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

