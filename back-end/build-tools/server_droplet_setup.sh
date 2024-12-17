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
SERVER_USER="root"                    # Assuming root user
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"  # Path to private SSH key on local machine
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

# Function to set up the new user
setup_new_user() {
  success "Setting up the new user:'$NEW_USER' on the server..."
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

# Function to run the server installation script
install() {
  success "Running server_droplet_installs.sh..."
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e
    cd "$SERVER_BULID_TOOLS_DIR"
    sudo ./server_droplet_installs.sh
EOF

  if [ $? -eq 0 ]; then
    success "Server installation script executed successfully!"
  else
    error "Failed to execute the server installation script."
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

# Function to configure Nginx on the server
nginx_site_available() {
  success "Configuring Nginx on the server..."

  # SSH into the server and set up Nginx
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e

    # Create the Nginx configuration
    sudo tee /etc/nginx/sites-available/$DOMAIN_NAME > /dev/null << NGINX_CONF
server {
    listen 80;
    server_name www.\$DOMAIN_NAME \$DOMAIN_NAME;

    location / {
        # Define the root directory if needed (you can change this based on your app's location)
        root /var/www/html;
        index index.html;
    }
}
NGINX_CONF

    # Enable the Nginx site
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

    # Test Nginx configuration and reload if successful
    if sudo nginx -t; then
      sudo systemctl reload nginx
    else
      error "Nginx configuration test failed."
      exit 1
    fi
EOF

  if [ $? -eq 0 ]; then
    success "Nginx configured and reloaded successfully!"
  else
    error "Failed to configure Nginx."
    exit 1
  fi
}

# Main Execution
success "Starting server droplet setup process..."
setup_new_user
configure_private_ssh_key
clone_repository
transfer_envfile
install
nginx_site_available
make_back_end_services
success "All tasks completed successfully!"