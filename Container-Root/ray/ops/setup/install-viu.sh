#!/bin/bash

# Install viu
# Source: https://github.com/atanunq/viu

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
apt update
apt install -y build-essential
cargo install viu

