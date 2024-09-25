#!/bin/bash


# Check if a model name is provided as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No job name provided."
    echo "Usage: $0 <job_name>"
    echo "List of jobs to choose from:"
    echo ""
    ./rayjob-status.sh
    echo -e "\n"
    exit 1
fi

# Set the model name from the argument
JOB=$1

# Convert the model name to lowercase for consistency
JOB=$(echo "$JOB" | tr '[:upper:]' '[:lower:]')

CMD="kubectl delete rayjob $JOB -n kuberay"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "RayJob deleted successfully for job: $JOB."
    echo "Run './rayjob-status.sh' to confirm deleted status."
else
    echo "Error deleting RayJob for job: $JOB"
    exit 3
fi

