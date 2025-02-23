#!/bin/bash

# Load .env file
LOCAL_ENV_FILE="$(dirname "$0")/.env"
if [ -f "$LOCAL_ENV_FILE" ]; then
  source "$LOCAL_ENV_FILE"
else
  echo "Error: .env file not found at $LOCAL_ENV_FILE"
  exit 1
fi

# Variables from .env file
SERVER_IP="${SERVER_IP}"  
NEW_USER="${NEW_USER}"  
SERVER_REPO_DIR="/home/$NEW_USER/zeheb"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Functions
success() { echo -e "${GREEN}$1${RESET}"; }
error() { echo -e "${RED}$1${RESET}"; exit 1; }

# Function to clone the repository on the server
clone_repository() {
  start "Cloning the GitHub repository on the server droplet..."
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e
    ssh-keyscan github.com >> ~/.ssh/known_hosts

    # Check if the directory exists
    echo "Checking if repository directory exists..."
    if [ -d "$SERVER_REPO_DIR" ]; then
      echo "Repository directory exists. Deleting old repository and cloning again..."
      sudo rm -rf "$SERVER_REPO_DIR"  # Delete the entire repository directory
    fi

    # Create the directory again and clone the repository
    echo "Creating the directory and cloning the repository..."
    mkdir -p "$SERVER_REPO_DIR"
    cd "$SERVER_REPO_DIR"

    echo "Cloning the repository..."
    git clone "$REPO_GIT_SSH_LINK" .

    # Change ownership to the appropriate user after cloning
    sudo chown -R mutu:mutu "$SERVER_REPO_DIR"
EOF

  if [ $? -eq 0 ]; then
    success "Repository cloned or updated successfully on the server."
  else
    error "Failed to clone or update the repository on the server."
    exit 1
  fi
}

transfer_envfile() {
  if [ "$1" = true ]; then
    success "Copying the .env file to the server..."
    scp "$LOCAL_ENV_FILE" "$NEW_USER@$SERVER_IP:$SERVER_REPO_DIR/back-end/build-tools/.env"
    [ $? -eq 0 ] && success "Successfully transferred .env file!" || error "Failed to transfer .env file."
  fi
}

make_back_end_services() {
  if [ "$1" = true ]; then
    success "Running 'make' commands for back-end services..."
    ssh "$NEW_USER@$SERVER_IP" << EOF
      set -e
      cd "$SERVER_REPO_DIR/back-end/build-tools"
      echo "🔥 Building backend micro Services..."
      sudo make -s build
EOF
    [ $? -eq 0 ] && success "Back-end services restarted successfully!" || error "Failed to restart back-end services."
  fi
}

build_web_app() {
  if [ "$1" = true ]; then
    success "Building React web application locally..."
    LOCAL_WEB_APP_DIR="/home/mutu/projects/zeheb/web-app"
    
    # Step 1: Check and build the React app
    if [ ! -d "$LOCAL_WEB_APP_DIR" ]; then
      error "Local web app directory $LOCAL_WEB_APP_DIR does not exist."
      exit 1
    fi

    cd "$LOCAL_WEB_APP_DIR" || exit
    npm install --legacy-peer-deps || error "Failed to install dependencies."
    npm run build || error "Failed to build the web app."
    success "Build completed successfully!"

    # Step 2: Ensure the target directory exists on the server
    success "Ensuring the target directory exists on the server..."
    ssh "$NEW_USER@$SERVER_IP" << EOF
      set -e
      sudo mkdir -p /var/www/html
      sudo chown -R $NEW_USER:$NEW_USER /var/www/html
EOF
    if [ $? -ne 0 ]; then
      error "Failed to prepare the target directory on the server."
      exit 1
    fi

    # Step 3: Copy build files to the server
    success "Copying build files to the server..."
    scp -r "$LOCAL_WEB_APP_DIR/build/" "$NEW_USER@$SERVER_IP:/var/www/html" || error "Failed to copy build files."

  fi
}


# Main Execution
success "******** STARTING PRODUCTION APPROVE PROCESS ********"
clone_repository true
transfer_envfile true
make_back_end_services true
build_web_app true
success "All tasks completed successfully!"