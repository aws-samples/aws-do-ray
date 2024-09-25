#!/bin/bash

CMD="kubectl get rayjob"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

