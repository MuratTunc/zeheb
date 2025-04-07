#!/bin/bash

# Load .env file
LOCAL_ENV_FILE="$(dirname "$0")/.env"  # Path to the .env file (same directory as this script)

if [ -f "$LOCAL_ENV_FILE" ]; then
  source "$LOCAL_ENV_FILE"
else
  echo "Error: .env file not found at $LOCAL_ENV_FILE"
  exit 1
fi

# Variables from .env file
SERVER_IP="${SERVER_IP}"  
NEW_USER="${NEW_USER}"    
DOMAIN_NAME="${DOMAIN_NAME}"  
REPO_GIT_SSH_LINK="${REPO_GIT_SSH_LINK}"

SERVER_BULID_TOOLS_DIR="/home/$NEW_USER/zeheb/back-end/build-tools"  # Directory for the install script

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

# Function to display success messages
success() {
  echo -e "✅ ${GREEN}$1${RESET}"
}

# Function to display error messages
error() {
  echo -e "❌ ${RED}$1${RESET}"
}


# Function to copy .env file to the server
transfer_envfile() {
  success "Copying the .env file to the server..."
  scp "$LOCAL_ENV_FILE" "$NEW_USER@$SERVER_IP:$SERVER_BULID_TOOLS_DIR/.env"
  if [ $? -eq 0 ]; then
    success ".env file copied successfully to $SERVER_BULID_TOOLS_DIR."
  else
    error "Failed to copy the .env file to the server."
    exit 1
  fi
}

# Main Execution
success "Starting server droplet transfer env file process..."
transfer_envfile

success "All tasks completed successfully!"
echo "✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅"