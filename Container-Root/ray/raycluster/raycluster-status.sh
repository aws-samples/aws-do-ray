#!/bin/bash

CMD="kubectl get raycluster"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

