#!/bin/bash

CMD="kubectl get rayservice -n kuberay"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
