#!/bin/bash

# Check if the submission_id is passed as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No job name provided."
    echo "Usage: $0 <job>"
    echo ""
    echo "List of jobs to choose from:"
    echo ""
    ./rayjob-status.sh
    echo -e "\n"
    exit 1
fi

# Assign the user's input to a variable
JOB=$1

CMD="kubectl logs -l=job-name=$JOB -n kuberay"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
