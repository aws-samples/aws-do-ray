#!/bin/bash

CMD="kubectl get rayservice"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
