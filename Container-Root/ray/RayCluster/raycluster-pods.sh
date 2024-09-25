#!/bin/bash

CMD="kubectl get pods --namespace kuberay"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

