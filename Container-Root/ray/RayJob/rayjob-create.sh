#!/bin/bash


# Check if a job name is provided as an argument
if [ -z "$1" ]; then
    echo ""
    echo "Error: No job name provided."
    echo "Usage: ./rayjob-create.sh <job_name>"
    echo "Available jobs: test-counter"
    echo ""
    exit 1
fi

# Set the job name from the argument
JOB=$1

# Convert the job name to lowercase for consistency
JOB=$(echo "$JOB" | tr '[:upper:]' '[:lower:]')

# # Apply the appropriate YAML file based on the job name
# if [ "$JOB" == "test-counter" ]; then
#     kubectl apply -f ${JOB}/ray-job.${JOB}.yaml -n kuberay
# else
#     echo "Error: Invalid job name. Available options are: test-counter."
#     exit 2
# fi

kubectl apply -f ${JOB}/ray-job.${JOB}.yaml -n kuberay

# Check if the kubectl apply command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the job configuration for ${JOB}."
    exit 1
fi


# Confirm successful deployment
if [ $? -eq 0 ]; then
    echo "RayJob deployed successfully for job: $JOB."
    echo "Run './rayjob-status.sh' to view the job status."
    echo "Run './rayjob-pods.sh' to view job pods."
    echo "Run './rayjob-logs.sh $JOB' to view job pods."
else
    echo "Error deploying RayJob for job: $JOB"
    exit 3
fi

