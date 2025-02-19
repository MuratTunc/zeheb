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

SERVER_USER="root"                    # Assuming root user
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"  # Path to private SSH key on local machine
SERVER_REPO_DIR="/home/$NEW_USER/zeheb"  # Dynamically set the repository directory based on NEW_USER
SERVER_BULID_TOOLS_DIR="/home/$NEW_USER/zeheb/back-end/build-tools"  # Directory for the install script

LOCAL_ENV_FILE="$(dirname "$0")/.env"  # Path to the .env file (same directory as this script)


# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# Function to display start messages
start() {
  echo -e "*********************************************"
  echo -e "🔄🔄🔄 ${YELLOW}$1${RESET}"
}


# Function to display success messages
success() {
  echo -e "✅✅✅ ${GREEN}$1${RESET}"
}

# Function to display error messages
error() {
  echo -e "❌❌❌ ${RED}$1${RESET}"
}

# Function to set up the new user
setup_new_user() {
  start "Setting up the new user:'$NEW_USER' on the server..."
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
  start "Copying the private SSH key to the server for user '$NEW_USER'..."
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

# Function to copy .env file to the server
transfer_envfile() {
  start "Copying the .env file to the server..."
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
  start "Running server_droplet_installs.sh..."
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
  start "Running 'make' commands for back-end services..."
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e  # Exit immediately if a command fails
    set -x  # Print each command before executing (debug mode)
    cd "$SERVER_BULID_TOOLS_DIR"
    echo "🔥 Building Services..."
    sudo make -s build
EOF

  if [ $? -eq 0 ]; then
    success "Back-end services built and started successfully!"
  else
    error "Failed to build and start back-end services."
    exit 1
  fi
}

# Function to  build web-app react apps and copy build files to derver droplet
build_web_app_in_local_pc() {
    start "Building React web application locally..."
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

nginx_file_transfer() {
  start "Transfer Nginx conf file to server droplet..."

  DOMAIN_NAME="${DOMAIN_NAME}"
  SCRIPT_DIR="/home/mutu/projects/zeheb/back-end/build-tools"  # Update if necessary
  LOCAL_NGINX_CONF_FILE="$SCRIPT_DIR/$DOMAIN_NAME.conf"

  # Debugging: Print paths
  echo "🔎 Checking for: $LOCAL_NGINX_CONF_FILE"

  # Check if the file exists locally
  if [ ! -f "$LOCAL_NGINX_CONF_FILE" ]; then
    error "❌ Local Nginx config file '$LOCAL_NGINX_CONF_FILE' does not exist!"
    exit 1
  fi

  # Ensure directory exists
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e
    if [ ! -d "/etc/nginx/sites-available" ]; then
      sudo mkdir -p /etc/nginx/sites-available
      echo "✅ Created /etc/nginx/sites-available directory."
    else
      echo "ℹ️ /etc/nginx/sites-available already exists."
    fi
EOF

  # Transfer file to a temporary location first (where user has access)
  scp "$LOCAL_NGINX_CONF_FILE" "$NEW_USER@$SERVER_IP:/tmp/$DOMAIN_NAME.conf"

  # Move the file to the correct directory using sudo
  ssh "$NEW_USER@$SERVER_IP" << EOF
    sudo mv /tmp/$DOMAIN_NAME.conf /etc/nginx/sites-available/$DOMAIN_NAME.conf
    sudo chown root:root /etc/nginx/sites-available/$DOMAIN_NAME.conf
    sudo chmod 644 /etc/nginx/sites-available/$DOMAIN_NAME.conf
EOF

  if [ $? -eq 0 ]; then
    success "✅ Nginx configuration transferred successfully!"
  else
    error "❌ Failed to transfer Nginx configuration."
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
build_web_app_in_local_pc
nginx_file_transfer
success "All tasks completed successfully!"
echo "✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅"