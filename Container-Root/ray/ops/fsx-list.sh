#!/bin/bash

export AWS_PAGER=""
aws fsx describe-file-systems --query 'FileSystems[].{FileSystemId:FileSystemId, Lifecycle:Lifecycle}'

