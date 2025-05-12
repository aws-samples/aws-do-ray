#!/bin/bash
source ../../env_vars

anyscale job submit --cloud ${CLOUD_NAME} --working-dir https://github.com/anyscale/docs_examples/archive/refs/heads/main.zip -- python hello_world.py


