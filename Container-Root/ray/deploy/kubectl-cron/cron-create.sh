#!/bin/bash

source ../../../../.env
export IMAGE=cron-job

# Deploying service-account.yaml
echo "Deploying service-account.yaml..."
kubectl apply -f service-account.yaml

# Deploying role.yaml
echo "Deploying role.yaml..."
kubectl apply -f role.yaml

# Deploying role-binding.yaml
echo "Deploying role-binding.yaml..."
kubectl apply -f role-binding.yaml


# Deploying cron-job.yaml
echo "Deploying cron-job.yaml..."
envsubst < cron-job.yaml | kubectl apply  -f -
