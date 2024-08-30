#!/bin/bash

PID_FILE="$HOME/port-forward2.pid"
# kubectl port-forward --address 0.0.0.0 service/raycluster-kuberay-head-svc 8265:8265 > /dev/null 2>&1 &
kubectl port-forward --address 0.0.0.0 deployment/prometheus-grafana -n prometheus-system 3000:3000 > /dev/null 2>&1 &
echo $! > "$PID_FILE"
echo "Port-forward started, PID $! saved in $PID_FILE"