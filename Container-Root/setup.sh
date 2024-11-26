#!/bin/sh

if [ -d /etc/apt ]; then
        [ -n "$http_proxy" ] && echo "Acquire::http::proxy \"${http_proxy}\";" > /etc/apt/apt.conf; \
        [ -n "$https_proxy" ] && echo "Acquire::https::proxy \"${https_proxy}\";" >> /etc/apt/apt.conf; \
        [ -f /etc/apt/apt.conf ] && cat /etc/apt/apt.conf
fi

echo 'Etc/UTC' | tee /etc/timezone
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata



# Install basic tools
apt-get update && apt-get install -y curl jq vim nano less unzip git gettext-base groff sudo htop bash-completion wget lsof

# Install aws cli
./ray/ops/setup/install-aws-cli.sh

# Install eksctl
./ray/ops/setup/install-eksctl.sh

# Install kubectl
./ray/ops/setup/install-kubectl.sh

# Install docker
./ray/ops/setup/install-docker.sh

# Install python
./ray/ops/setup/install-python.sh
python -m pip install torchx[kubernetes]

# Install ray
./ray/ops/setup/install-ray.sh

# Install helm
./ray/ops/setup/install-helm.sh

# Install kustomize
./ray/ops/setup/install-kustomize.sh

# Install kubectx
./ray/ops/setup/install-kubectx.sh

# Install kubeps1 and aliases
./ray/ops/setup/install-kubeps1.sh
./ray/ops/setup/install-bashrc.sh

# Install kubetail
./ray/ops/setup/install-kubetail.sh

# Install kubeshell
./ray/ops/setup/install-kubeshell.sh

# Install k9s
./ray/ops/setup/install-k9s.sh

# Install stern using krew
./ray/ops/setup/install-krew.sh
./ray/ops/setup/install-stern.sh

# Install viu
./ray/ops/setup/install-viu.sh

# Install sbom utils
./ray/ops/setup/install-sbom-utils.sh

# # AWS Credentials
# # AWS Credentials setup
# if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] && [ -n "$AWS_SESSION_TOKEN" ]; then
#   # Create AWS directory and files
#   mkdir -p /root/.aws

#   # Set AWS credentials
#   cat > /root/.aws/credentials << EOL
# [default]
# aws_access_key_id = $AWS_ACCESS_KEY_ID
# aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
# aws_session_token = $AWS_SESSION_TOKEN
# EOL

#   # Set AWS default region and output format
#   if [ -n "$AWS_REGION" ]; then
#     cat > /root/.aws/config << EOL
# [default]
# region = $AWS_REGION
# output = json
# EOL
#   fi
# fi

