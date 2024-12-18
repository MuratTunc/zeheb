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

# Function to  build web-app react apps and copy build files to derver droplet
build_web_app() {
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

  
}

# Function to configure Nginx on the server
nginx_site_available() {
  success "Configuring Nginx on the server..."

  # SSH into the server and set up Nginx
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e

    # Copy the Nginx configuration file from the cloned repository to the correct location
    sudo cp $SERVER_BULID_TOOLS_DIR/$DOMAIN_NAME /etc/nginx/sites-available/$DOMAIN_NAME

    # Enable the Nginx site
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

    # Test Nginx configuration and reload if successful
    if sudo nginx -t; then
      sudo systemctl reload nginx
      sudo chown -R www-data:www-data /var/www/html/build
      sudo chmod -R 755 /var/www/html/build
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
make_back_end_services
build_web_app
nginx_site_available
success "All tasks completed successfully!"