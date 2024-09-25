#!/bin/bash

CMD="kubectl get rayjob --namespace kuberay"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

