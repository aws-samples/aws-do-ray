#!/bin/bash

CMD="kubectl get raycluster --namespace kuberay"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

