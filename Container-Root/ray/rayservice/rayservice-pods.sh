#!/bin/bash

CMD="kubectl get pods -n kuberay"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

