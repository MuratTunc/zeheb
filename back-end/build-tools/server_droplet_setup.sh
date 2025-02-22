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

# Function to generate Nginx config
generate_nginxConfiguration_file() {
  start "Generating Nginx configuration file..."
  
  SCRIPT_DIR="$(dirname "$0")"
  GENERATE_SCRIPT="$SCRIPT_DIR/generate_nginx_config.sh"

  if [ -f "$GENERATE_SCRIPT" ]; then
    chmod +x "$GENERATE_SCRIPT"  # Ensure it's executable
    "$GENERATE_SCRIPT"

    if [ $? -eq 0 ]; then
      success "Nginx configuration file generated successfully!"
    else
      error "Failed to generate Nginx configuration file."
      exit 1
    fi
  else
    error "generate_nginx_config.sh script not found in $SCRIPT_DIR"
    exit 1
  fi
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


# Function to copy Nginx configuration file to the server
transfer_nginxConfiguration_file() {
  start "Copying the DNS Nginx configuration file to the server..."
  
  NGINXCONF_FILE_DIR="$(dirname "$0")"
  NGINXCONF_FILE_PATH="$NGINXCONF_FILE_DIR/$DOMAIN_NAME"

  # First, copy the file to a temporary directory on the remote server
  scp "$NGINXCONF_FILE_PATH" "$NEW_USER@$SERVER_IP:/tmp/$DOMAIN_NAME"

  if [ $? -eq 0 ]; then
    success "Nginx config file copied to temporary directory on the server."

    # Move the file to /etc/nginx/sites-available/ with sudo on the server
    ssh "$NEW_USER@$SERVER_IP" << EOF
      sudo mv /tmp/$DOMAIN_NAME /etc/nginx/sites-available/$DOMAIN_NAME
      sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
      sudo systemctl reload nginx
EOF

    if [ $? -eq 0 ]; then
      success "Nginx config file successfully moved and activated."
    else
      error "Failed to move Nginx config file to /etc/nginx/sites-available/."
      exit 1
    fi
  else
    error "Failed to copy the Nginx config file to the server."
    exit 1
  fi
}





# Function to run the server installation script
install_systemPackages() {
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

nginx_configuration() {
  success "Configuring Nginx on the server..."

  # SSH into the server and set up Nginx
  ssh "$NEW_USER@$SERVER_IP" << EOF
    set -e

    # Debug: Print domain name
    echo "Checking domain name: $DOMAIN_NAME"

    # Enable the Nginx site
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

    # Test Nginx configuration and reload if successful
    if sudo nginx -t; then
      sudo systemctl reload nginx
      sudo chown -R www-data:www-data /var/www/html/build
      sudo chmod -R 755 /var/www/html/build

      # Create .well-known/acme-challenge/ directory and set permissions
      sudo mkdir -p /var/www/html/.well-known/acme-challenge/
      sudo chmod -R 755 /var/www/html/.well-known/
      sudo chown -R www-data:www-data /var/www/html/.well-known/

      # Create a test file to verify the Nginx server is properly serving the challenge
      echo "test" | sudo tee /var/www/html/.well-known/acme-challenge/testfile

      # Debug: Check if the domain resolves
      dig +short $DOMAIN_NAME

      # Check if the test file is being served correctly
      if curl -I http://$DOMAIN_NAME/.well-known/acme-challenge/testfile; then
        echo "Test file is accessible!"
      else
        echo "Test file is not accessible. Please check the Nginx configuration."
        exit 1
      fi

    else
      echo "Nginx configuration test failed."
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



install_ssl() {
  echo "🔒🔒🔒 Installing Let's Encrypt SSL for $DOMAIN_NAME.com and www.$DOMAIN_NAME.com..."

  # Ensure Nginx is installed and running
  if ! command -v nginx &>/dev/null; then
    echo "⚠️ Nginx is not installed. Installing it now..."
    sudo apt update
    sudo apt install -y nginx
  fi

  sudo systemctl start nginx
  sudo systemctl enable nginx

  # Install Certbot if not installed
  if ! command -v certbot &>/dev/null; then
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
  fi

  # Ensure UFW allows HTTPS (if UFW is installed)
  if command -v ufw &>/dev/null; then
    echo "🔄 Updating firewall rules..."
    sudo ufw allow 'Nginx Full'
    sudo ufw reload
  fi

  echo "🔒🔒🔒 Running Certbot to obtain and install SSL"

  sudo certbot --nginx -d "$DOMAIN_NAME.com" -d "www.$DOMAIN_NAME.com" --non-interactive --agree-tos --email murat.tunc8558@gmail.com --redirect

  if [ $? -eq 0 ]; then
    echo "✅ SSL installed successfully for $DOMAIN_NAME.com and www.$DOMAIN_NAME.com!"
  else
    echo "❌ SSL installation failed!"
    exit 1
  fi
}

# Function to test DNS resolution and compare with expected IP
test_dns_resolution() {
  success "Testing DNS resolution for domain..."

  # Use dig to get the IP addresses for the domain and www subdomain
  dig_ip=$(dig +short $DOMAIN_NAME)
  dig_www_ip=$(dig +short www.$DOMAIN_NAME)

  # Compare the IPs with SERVER_IP
  if [[ "$dig_ip" == "$SERVER_IP" && "$dig_www_ip" == "$SERVER_IP" ]]; then
    success "DNS resolution is correct for $DOMAIN_NAME and www.$DOMAIN_NAME. IP matches $SERVER_IP."
  else
    error "DNS resolution mismatch! Expected IP: $SERVER_IP, but got $dig_ip for $DOMAIN_NAME and $dig_www_ip for www.$DOMAIN_NAME."
    exit 1
  fi
}




# Main Execution
#-------------------------------------#
success "Starting server droplet setup process..."
#-------------------------------------#

#-------------------------------------#
setup_new_user
#-------------------------------------#

#-------------------------------------#
configure_private_ssh_key
#-------------------------------------#

#-------------------------------------#
clone_repository
#-------------------------------------#

#From Developmetn PC to SERVER DROPLET.
#-------------------------------------#
transfer_envfile

#-------------------------------------#

#-------------------------------------#
install_systemPackages
#-------------------------------------#

#-------------------------------------#
generate_nginxConfiguration_file
transfer_nginxConfiguration_file
#-------------------------------------#

#-------------------------------------#
make_back_end_services
#-------------------------------------#

#-------------------------------------#
build_web_app_in_local_pc
#-------------------------------------#

#-------------------------------------#
nginx_configuration
install_ssl

#💡 Next Steps After SSL Installation
# Test HTTPS:
test_dns_resolution
#-------------------------------------#



success "All tasks completed successfully!"
echo "✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅"