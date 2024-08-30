#!/bin/bash

kubectl port-forward --address 0.0.0.0 service/rayservice-sample-head-svc 8000:8000 > /dev/null 2>&1 &

echo $! > "$PID_FILE"
echo "Port-forward started, PID $! saved in $PID_FILE"