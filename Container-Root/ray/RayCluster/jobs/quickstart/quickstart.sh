#!/bin/bash

# Once the KubeRay operator is running, we are ready to deploy a RayCluster. To do so, we create a RayCluster Custom Resource in the default namespace
helm install raycluster kuberay/ray-cluster --version 1.1.0

# We can verify that the RayCluster is deployed by listing the RayClusters in the default namespace.
kubectl get rayclusters

# View RayCluster CR
kubectl get rayclusters

# KubeRay operator will detect the RayCluster object. the operator will then start your Ray cluster by creating head and worker pods. 
kubectl get pods --selector=ray.io/cluster=raycluster-kuberay
