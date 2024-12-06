#!/bin/bash

# Variables
SERVER_IP="24.199.103.191"            # Replace with your server IP
SERVER_USER="root"                   # Assuming root user
NEW_USER="mutu7"                      # New user being set up
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"  # Path to private SSH key on local machine
REPO_GIT_SSH_LINK="git@github.com:MuratTunc/zeheb.git"  # GitHub repository SSH link
SERVER_REPO_DIR="/home/$NEW_USER/zeheb"  # Dynamically set the repository directory based on NEW_USER

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

# Function to set up the new user
setup_new_user() {
  success "Setting up the new user on the server..."
  ssh "$SERVER_USER@$SERVER_IP" << EOF
    set -e  # Exit immediately if any command fails

    # Check if the user exists
    if id "$NEW_USER" &>/dev/null; then
      echo "User '$NEW_USER' already exists. Skipping user creation and password setting."
    else
      echo "Creating user '$NEW_USER'..."
      useradd -m -s /bin/bash "$NEW_USER"
      echo "$NEW_USER:$NEW_USER" | chpasswd
      echo "Password set to '$NEW_USER'. Please change it after setup."
    fi

    echo "Setting up .ssh directory for '$NEW_USER'..."
    mkdir -p /home/$NEW_USER/.ssh
    chmod 0700 /home/$NEW_USER/.ssh/
    cp -Rfv /root/.ssh /home/$NEW_USER/
    chown -Rfv $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

    echo "Adding '$NEW_USER' to the sudo group..."
    gpasswd -a $NEW_USER sudo

    echo "Configuring passwordless sudo for '$NEW_USER'..."
    echo "$NEW_USER ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

    echo "Restarting SSH service..."
    service ssh restart

    echo "Setting default shell for '$NEW_USER'..."
    usermod -s /bin/bash $NEW_USER

    echo "User setup completed for '$NEW_USER'..."
EOF

  if [ $? -eq 0 ]; then
    success "New user setup completed successfully!"
  else
    error "Failed to set up the new user on the server."
    exit 1
  fi
}

# Function to configure the private SSH key for the new user
configure_private_ssh_key() {
  success "Copying the private SSH key to the server for user '$NEW_USER'..."
  scp "$PRIVATE_KEY_PATH" "$NEW_USER@$SERVER_IP:/home/$NEW_USER/.ssh/id_rsa"
  if [ $? -eq 0 ]; then
    success "Private SSH key copied successfully!"
  else
    error "Failed to copy the private SSH key to the server."
    exit 1
  fi

  ssh "$NEW_USER@$SERVER_IP" << EOF
    chmod 600 /home/$NEW_USER/.ssh/id_rsa
    chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/id_rsa
    ssh-keyscan github.com >> /home/$NEW_USER/.ssh/known_hosts
EOF

  if [ $? -eq 0 ]; then
    success "Private SSH key permissions set and GitHub added to known_hosts!"
  else
    error "Failed to configure the private SSH key for the new user."
    exit 1
  fi
}

# Function to clone the repository on the server
clone_repository_on_server() {
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

# Main Execution
success "Starting server droplet setup process..."
setup_new_user
configure_private_ssh_key
clone_repository_on_server
success "All tasks completed successfully!"
