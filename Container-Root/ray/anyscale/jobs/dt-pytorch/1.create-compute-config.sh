#!/bin/bash
cat compute_config_template.yaml | envsubst > compute_config.yaml
anyscale compute-config create -f compute_config.yaml -n compute_config
