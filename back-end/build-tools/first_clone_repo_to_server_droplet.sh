#!/bin/bash

# Define the parameters directly in the script
REPO_GIT_SSH_LINK="git@github.com:MuratTunc/zeheb.git"  # GitHub repository SSH link
SERVER_USER="mutu"  # Server username
SERVER_IP="64.23.150.141"  # Server IP address
SERVER_REPO_DIR="/home/mutu/zeheb"  # Directory on the server where the repo will be cloned

# 1. Copy the script to the server (for reference)
echo "Copying the repository cloning script to the server droplet..."
scp ./first_clone_repo_to_server_droplet.sh "$SERVER_USER@$SERVER_IP:/home/$SERVER_USER/first_clone_repo_to_server_droplet.sh"

# Check if the script was copied successfully
if [ $? -ne 0 ]; then
  echo "Failed to copy the script to the server. Exiting..."
  exit 1
fi

# 2. SSH into the server and start cloning the repository
echo "Cloning the GitHub repository on the server..."
ssh "$SERVER_USER@$SERVER_IP" << EOF
  # Add GitHub's SSH key to known_hosts
  ssh-keyscan github.com >> ~/.ssh/known_hosts

  # Ensure the directory exists
  mkdir -p "$SERVER_REPO_DIR"
  
  # Clone the repository into the desired directory
  cd "$SERVER_REPO_DIR"
  git clone "$REPO_GIT_SSH_LINK"
EOF

# Check if the clone was successful
if [ $? -eq 0 ]; then
  echo "Repository cloned successfully to $SERVER_REPO_DIR on the server."
else
  echo "Failed to clone the repository on the server."
  exit 1
fi
