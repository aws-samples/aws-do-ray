#!/bin/bash

ray-expose.sh

echo -e "JOBS:-------- \n"

ray job list --address http://localhost:8265 | sed -n "s/.*submission_id='\([^']*\)'.*entrypoint='\([^']*\)'.*/submission_id: \1, entrypoint: \2/p"

echo -e "\nTo get the status of a job, please run './job-status.sh <submission_id>' where <submission_id> is listed for your jobs above."
echo -e "\nTo get the logs of a job, please run './job-logs.sh <submission_id>' where <submission_id> is listed for your jobs above."
echo -e "\nTo stop a job, please run './job-stop.sh <submission_id>' where <submission_id> is listed for your jobs above.\n"
