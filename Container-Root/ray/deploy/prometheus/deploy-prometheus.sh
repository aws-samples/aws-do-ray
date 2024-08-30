#!/bin/bash


./kuberay/install/prometheus/install.sh

echo "Checking installation"

kubectl get all -n prometheus-system



