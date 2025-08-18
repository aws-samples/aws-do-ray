#!/bin/bash
cat job_config_template.yaml | envsubst > job_config.yaml
anyscale job submit -f job_config.yaml
