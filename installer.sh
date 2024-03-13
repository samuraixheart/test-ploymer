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

# Function to prompt the user for input and append new variables to .env file
prompt_and_append_to_env() {
    local env_file="$1"
    shift

    # Prompt the user to input values for each variable
    for var in "$@"; do
        read -p "Enter the value for $var: " value
        append_to_env "$env_file" "$var='$value'"
    done
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

# Install Node.js if not already installed and skip if version is 20.xx.xx or greater
if [ -z "$skip_node_installation" ]; then
    echo "Installing Node.js"
    sudo_interactive apt update && sudo_interactive apt install -y nodejs
fi

# Function to clone repository interactively
clone_repository() {
    local repo_url=$1
    if [ -z "$repo_url" ]; then
        if [ -t 0 ]; then
            # Interactive mode, prompt for repository URL
            read -p "Enter the repository URL: " repo_url
            if [ -z "$repo_url" ]; then
                echo "Repository URL is required. Aborting script."
                exit 1
            fi
        else
            # Non-interactive mode, exit
            echo "Repository URL is required. Aborting script."
            exit 1
        fi
    fi
    git clone "$repo_url" && cd "$(basename "$repo_url" .git)"
}

# 1. Clone the repository interactively
echo "Step 1: Cloning the repository"
clone_repository "$1"

# Remaining steps...



# 2. Update apt repositories
echo "Step 2: Updating apt repositories"
sudo_interactive apt update

# 3. Install Foundry using curl
echo "Step 3: Installing Foundry"
sudo_interactive curl -L https://foundry.paradigm.xyz | bash

# 4. Reload bashrc
echo "Step 4: Reloading bashrc"
source ~/.bashrc

# 5. Run foundryup command
echo "Step 5: Running foundryup command"
foundryup

# 6. Add prebuilt-mpr archive key and repository
echo "Step 6: Adding prebuilt-mpr archive key and repository"
sudo_interactive wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg > /dev/null
echo "deb [arch=all,\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr \$(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list > /dev/null
# 7. Update apt repositories and install just
echo "Step 7: Updating apt repositories and installing just"
sudo_interactive apt update && sudo_interactive apt install just

# 8. Install just in the cloned repository directory
echo "Step 8: Installing just in the cloned repository directory"
just install

# 9. Copy .env.example to .env
echo "Step 9: Copying .env.example to .env"
cp .env.example .env

# 11. Prompt the user to input values for new variables and append them to .env file
echo "Step 11: Adding new variables to .env file"
prompt_and_append_to_env .env \
    PRIVATE_KEY_1 \
    OP_ALCHEMY_API_KEY \
    BASE_ALCHEMY_API_KEY \
    OP_BLOCKSCOUT_API_KEY \
    BASE_BLOCKSCOUT_API_KEY

# 11. Run "just do-it" command
echo "Step 11: Running 'just do-it' command"
just do-it
