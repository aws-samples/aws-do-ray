#!/bin/bash

# Determine if cluster is EKS or HyperPod
export AWS_EKS_HYPERPOD_CLUSTER=$(ops/hyperpod-name.sh)
if [ "$AWS_EKS_HYPERPOD_CLUSTER" == "" ]; then
        export CLUSTER_TYPE=eks
else
        export CLUSTER_TYPE=hyperpod
fi

# Deploy KubeRay
NS_COUNT=$(kubectl get namespace kuberay | grep kuberay | wc -l)
if [ "$NS_COUNT" == "1" ]; then
    echo "Namespace kuberay already exists"
else
    kubectl create namespace kuberay
fi

# Deploy the KubeRay operator with the Helm chart repository
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update

#Install both CRDs and Kuberay operator v1.1.0
helm install kuberay-operator kuberay/kuberay-operator --version 1.1.0 --namespace kuberay

# Kuberay operator pod will be deployed onto head pod
kubectl get pods --namespace kuberay


# Create FSX for Lustre
echo "Creating FSX For Lustre Cluster..."
echo "Deploying FSX Dependences..."
./deploy/fsx/deploy.sh

echo "Dynamically Provisioning FSX For Lustre Cluster... this may take a few minutes"
./deploy/fsx/dynamic-create.sh

echo "Please wait until FSx Cluster is up and ready until you deploy Ray Cluster. Please check AWS Console, or run fsx-list.sh, or use alias fl, or run 'kubectl get pvc' and wait until status is 'Bound'"
