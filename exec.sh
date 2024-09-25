#!/bin/bash

source .env

if [ "$1" == "" ]; then
	CMD="/bin/bash"
else
	CMD="$@"
fi

CMDLN="docker container exec -it ${CONTAINER} $CMD"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMDLN}\n"; fi
eval "$CMDLN"

