#!/bin/bash

ray-expose.sh

# Check if the submission_id is passed as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No submission_id provided."
    echo "Usage: ./job-status.sh <submission_id>"
    echo "List of jobs to choose from:"
    echo ""
    ray job list --address http://localhost:8265 | sed -n "s/.*submission_id='\([^']*\)'.*entrypoint='\([^']*\)'.*/submission_id: \1, entrypoint: \2/p"
    echo -e "\n"
    exit 1
fi

# Assign the user's input to a variable
submission_id=$1

ray job status --address http://localhost:8265 $submission_id

echo -e "\n"
