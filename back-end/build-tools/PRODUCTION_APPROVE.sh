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
SERVER_IP="${SERVER_IP}"  # Loaded from .env
NEW_USER="${NEW_USER}"    # Loaded from .env
REPO_GIT_SSH_LINK="${REPO_GIT_SSH_LINK}"  # Loaded from .env GitHub repository SSH link
SERVER_REPO_DIR="/home/$NEW_USER/zeheb"  # Dynamically set the repository directory based on NEW_USER
SERVER_BULID_TOOLS_DIR="/home/$NEW_USER/zeheb/back-end/build-tools"  # Directory for the install script
LOCAL_ENV_FILE="$(dirname "$0")/.env"  # Path to the .env file (same directory as this script)

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

# Function to display success messages
success() {
  echo -e "${GREEN}$1${RESET}"
}

# Function to display error messages
error() {
  echo -e "${RED}$1${RESET}"
}

# Function to clone the repository on the server
clone_repository() {
  success "Cloning the GitHub repository on the server droplet..."
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    mkdir -p "$SERVER_REPO_DIR"
    cd "$SERVER_REPO_DIR"
    if [ -d ".git" ]; then
      echo "Repository already exists. Pulling latest changes..."
      git pull
    else
      echo "Cloning the repository into $SERVER_REPO_DIR..."
      git clone "$REPO_GIT_SSH_LINK" .
    fi
EOF

  if [ $? -eq 0 ]; then
    success "Repository cloned or updated successfully on the server."
  else
    error "Failed to clone or update the repository on the server."
    exit 1
  fi
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



# Function to run "make" commands for back-end services
make_back_end_services() {
  success "Running 'make' commands for back-end services..."
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e
    cd "$SERVER_BULID_TOOLS_DIR"
    echo "Stopping existing services with 'make down'..."
    sudo make down
    echo "Building and starting services with 'make up_build'..."
    sudo make up_build
EOF

  if [ $? -eq 0 ]; then
    success "Back-end services built and started successfully!"
  else
    error "Failed to build and start back-end services."
    exit 1
  fi
}

# Main Execution
success "********STARTING PRODUCTION APPROVE PROCESS********"
clone_repository
transfer_envfile
make_back_end_services
success "All tasks completed successfully!"