#!/bin/bash
source ./env_vars

echo -n "Please enter Anyscale Cloud Name: "
read CLOUD_NAME

if [ -z "$ANYSCALE_CLOUD_NAME" ]; then
    echo "Anyscale Cloud Name cannot be empty"
    exit 1
fi

kubectl delete deployment anyscale-operator -n anyscale

anyscale cloud delete --name $ANYSCALE_CLOUD_NAME

helm uninstall anyscale-operator -n anyscale
