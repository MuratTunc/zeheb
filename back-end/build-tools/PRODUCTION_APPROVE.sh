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
SERVER_WEB_APP_DIR="/home/$NEW_USER/zeheb/web-app"
SERVER_BUILD_DIR="/var/www/html"
DOMAIN_NAME="www.zehebfind.com"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Functions
success() { echo -e "${GREEN}$1${RESET}"; }
error() { echo -e "${RED}$1${RESET}"; exit 1; }

clone_repository() {
  if [ "$1" = true ]; then
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
    [ $? -eq 0 ] && success "Repository cloned or updated successfully!" || error "Failed to clone repository."
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
      sudo make down
      sudo make up_build
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
clone_repository false
transfer_envfile false
make_back_end_services false
build_web_app true
success "All tasks completed successfully!"