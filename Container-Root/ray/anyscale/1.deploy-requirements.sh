#!/bin/bash
# Getting variables
source ./env_vars

echo "Creating Anyscale namespace..."
kubectl create namespace ${NAMESPACE}

echo "Deploying Anyscale dependencies..."
pip install -U anyscale

anyscale login

helm repo add anyscale https://anyscale.github.io/helm-charts
helm repo update anyscale

echo "Installing Ingress-nginx..."

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml

# Enable snippet annotations
kubectl patch configmap ingress-nginx-controller -n ingress-nginx --type=merge -p '{"data":{"allow-snippet-annotations":"true"}}'

# Configure internet-facing load balancer
kubectl patch svc ingress-nginx-controller -n ingress-nginx --type=merge -p '{"metadata":{"annotations":{"service.beta.kubernetes.io/aws-load-balancer-scheme":"internet-facing"}}}'


echo "Labeling and Tainting nodes for Anyscale workers"

kubectl label nodes --all eks.amazonaws.com/capacityType=ON_DEMAND
