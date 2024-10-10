#!/bin/bash
# List pods and filter for those in "UnexpectedAdmissionError" state
PODS=$(kubectl get pods -o json | jq -r '.items[] | select(.status.reason == "UnexpectedAdmissionError") | .metadata.name')

# Delete the pods if any are found
if [ -n "$PODS" ]; then
  echo "Found pods in UnexpectedAdmissionError state: $PODS"
  for pod in $PODS; do
    echo "Deleting pod: $pod"
    kubectl delete pod $pod --force --grace-period=0
  done
else
  echo "No pods found in UnexpectedAdmissionError state."
fi
