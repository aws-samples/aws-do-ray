#!/bin/bash

ray-expose.sh

# Function to submit the job through the Ray SDK
submit_via_sdk() {
    echo "Submitting job '$1' through the Ray SDK..."
    local script_name="$1"
    local working_dir="$script_name"

    if [ -d "$working_dir" ]; then
        CMD="ray job submit --address http://localhost:8265 --working-dir \"$working_dir\" -- python3 \"$script_name.py\""
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
    else
        echo "Error: Working directory '$working_dir' does not exist."
        exit 1
    fi
}

# Function to submit the job through the Ray head pod
submit_via_head() {
    echo "Submitting job '$1' through the head pod..."
    local script_name="$1"
    local working_dir="$script_name"

    # Get the name of the head pod
    head_pod=$(kubectl get pods -n kuberay --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)

    # Check if the head pod is found
    if [ -z "$head_pod" ]; then
        echo "Error: Head pod not found."
        exit 1
    fi

    # Copy the script to the head pod
    if [ -d "$working_dir" ]; then
        kubectl cp "$working_dir/$script_name.py" "$head_pod:/tmp/$script_name.py" -n kuberay
    else
        echo "Error: Working directory '$working_dir' does not exist."
        exit 1
    fi

    # Run the Python script on the head pod
    CMD="kubectl exec -it "$head_pod" -n kuberay -- python \"/tmp/$script_name.py\""
    if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
    eval "$CMD"
}

# Function to submit the job from the local file system
submit_local_job() {
    echo "Submitting job from local file system..."
    local script_name="$1"
    local script_path="$2"

    head_pod=$(kubectl get pods -n kuberay --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)

    # Check if the head pod is found
    if [ -z "$head_pod" ]; then
        echo "Error: Head pod not found."
        exit 1
    fi

    # Check if the file exists inside the pod
    file_exists=$(kubectl exec "$head_pod" -n kuberay -- bash -c "[ -f $script_path/$script_name.py ] && echo 'true' || echo 'false'")

    if [ "$file_exists" == "true" ]; then
        # submit_via_head "$script_name"
        CMD="kubectl exec -it \"$head_pod\" -n kuberay -- python \"$script_path/$script_name.py\""
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
    else
        echo "Error: Path '$script_path/$script_name.py' does not exist."
        exit 1
    fi
}

# Check if a script name or path has been provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <script-name> [script-path]"
    exit 1
fi

script_name="$1"

# If a script path is provided, submit the job from the local file system
if [ "$#" -eq 2 ]; then
    script_path="$2"
    submit_local_job "$script_name" "$script_path"
    exit 0
fi

# Try submitting the job through the Ray SDK
submit_via_sdk "$script_name" || submit_via_head "$script_name"

