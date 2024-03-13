#!/bin/bash

# Function to run commands with sudo and interactively prompt for password
sudo_interactive() {
    # Check if sudo password is already cached
    if sudo -n true 2>/dev/null; then
        # If sudo password is cached, run the command directly
        sudo "$@"
    else
        # If sudo password is not cached, prompt for password interactively
        sudo -v
        # Run the command with sudo
        sudo "$@"
    fi
}

# Function to clone repository interactively
clone_repository() {
    read -p "Enter the repository URL: " repo_url
    git clone "$repo_url" && cd "$(basename "$repo_url" .git)"
}

# Function to append new variables to .env file without changing existing ones
append_to_env() {
    local env_file="$1"
    shift
    # Read existing variables from .env file
    local existing_variables
    existing_variables=$(grep -vE '^\s*#' "$env_file")

    # Append new variables to .env file
    cat <<EOF >> "$env_file"
$@
EOF

    # Append existing variables back to .env file
    echo "$existing_variables" >> "$env_file"
}

# Check if Node.js is already installed and its version is 20.xx.xx or greater
node_version=$(node -v)
if [[ "$node_version" =~ ^v([0-9]+)\. ]]; then
    major_version="${BASH_REMATCH[1]}"
    if (( major_version >= 20 )); then
        echo "Node.js version $node_version is already installed. Skipping Node.js installation."
        skip_node_installation=true
    fi
fi

# 1. Clone the repository interactively
echo "Step 1: Cloning the repository"
clone_repository

# 2. Install Node.js if not already installed
if [ -z "$skip_node_installation" ]; then
    echo "Step 2: Installing Node.js"
    sudo_interactive apt update && sudo_interactive apt install -y nodejs
fi

# Remaining steps...

