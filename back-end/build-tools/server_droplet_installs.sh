#!/bin/bash

# Load .env file
ENV_FILE="$(dirname "$0")/.env"  # Path to the .env file (same directory as this script)
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

USER_SERVICE_PORT="${USER_SERVICE_PORT}"
MAIL_SERVICE_PORT="${MAIL_SERVICE_PORT}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW="\033[0;33m"
RESET="\033[0m"

# Function to display start messages
start() {
  echo -e "*********************************************"
  echo -e "🔄🔄🔄 ${YELLOW}$1${RESET}"
}

# Function to print success messages
print_success() { echo -e "✅✅✅ ${GREEN}$1${NC}"; }

# Function to print error messages
print_error() { echo -e "❌❌❌ ${RED}$1${NC}"; }



# Function to check if script is run as root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Use sudo ./setup_server_installs.sh"
    exit 1
  fi
}

# Function to install curl
install_curl() {
  if ! command -v curl &>/dev/null; then
    start "curl not found, installing..."
    if apt install -y curl; then
      print_success "curl installed successfully."
    else
      print_error "Failed to install curl."
    fi
  else
    print_success "curl is already installed."
  fi
}

# Function to install net-tools (netstat)
install_netstat() {
  if ! command -v netstat &>/dev/null; then
    start "netstat not found, installing net-tools..."
    if apt install -y net-tools; then
      print_success "net-tools installed successfully."
    else
      print_error "Failed to install net-tools."
    fi
  else
    print_success "netstat is already installed."
  fi
}

# Function to update system packages
update_system_packages() {
  start "Updating package list..."
  if apt update && apt upgrade -y; then
    print_success "System packages updated successfully."
  else
    print_error "Failed to update system packages."
  fi
}

# Function to install and configure Nginx
install_nginx() {
  if ! nginx -v &>/dev/null; then
    start "Nginx is not installed. Installing Nginx..."

    # Install Nginx
    if apt install -y nginx; then
      print_success "Nginx installed successfully."

      # Enable and start Nginx if it's not active
      if ! systemctl is-active --quiet nginx; then
        sudo systemctl enable nginx && sudo systemctl start nginx
        print_success "Nginx started and enabled to start on boot."
      else
        print_success "Nginx is already running."
      fi
    else
      print_error "Failed to install Nginx."
      exit 1
    fi
  else
    print_success "Nginx is already installed."
    
    # Ensure Nginx is enabled and started
    if ! systemctl is-enabled --quiet nginx; then
      sudo systemctl enable nginx
      print_success "Nginx enabled to start on boot."
    fi

    if ! systemctl is-active --quiet nginx; then
      sudo systemctl start nginx
      print_success "Nginx started successfully."
    else
      print_success "Nginx is already running."
    fi
  fi

  # Allow HTTP (port 80) and HTTPS (port 443) through the firewall
  start "Checking and allowing ports  through the firewall..."
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw allow USER_SERVICE_PORT/tcp
  sudo ufw allow MAIL_SERVICE_PORT/tcp

  # Reload UFW to apply changes
  sudo ufw reload

  # Display the current UFW status
  start "Displaying current UFW status:"
  sudo ufw status verbose

}


# Function to install Docker
install_docker() {
  if ! docker --version &>/dev/null; then
    start "Installing Docker..."
    if apt install -y ca-certificates curl gnupg lsb-release &&
       mkdir -p /etc/apt/keyrings &&
       curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
       echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&
       apt update &&
       apt install -y docker-ce docker-ce-cli containerd.io; then
      print_success "Docker installed successfully."
    else
      print_error "Failed to install Docker."
    fi
  else
    print_success "Docker is already installed."
  fi
}

# Function to install Docker Compose
install_docker_compose() {
  if ! command -v docker-compose &>/dev/null; then
    start "Installing Docker Compose stand-alone binary..."
    if curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
       chmod +x /usr/local/bin/docker-compose; then
      print_success "Docker Compose installed successfully."
    else
      print_error "Failed to install Docker Compose."
    fi
  else
    print_success "Docker Compose is already installed."
  fi
}

# Function to install Certbot
install_certbot() {
  if ! certbot --version &>/dev/null; then
    start "Installing Certbot..."
    if apt install -y certbot python3-certbot-nginx; then
      print_success "Certbot installed successfully."
    else
      print_error "Failed to install Certbot."
    fi
  else
    print_success "Certbot is already installed."
  fi
}

# Function to install Make
install_make() {
  start "Installing Make..."
  if apt install -y make; then
    print_success "Make installed successfully."
  else
    print_error "Failed to install Make."
  fi
}

# Function to install Go
install_go() {
  start "Installing the latest version of Go..."
  GO_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+\.linux-amd64\.tar\.gz' | head -n 1)
  GO_VERSION_URL="https://go.dev/dl/${GO_VERSION}"

  if curl -fsSL "$GO_VERSION_URL" -o go.tar.gz &&
     sudo tar -C /usr/local -xzf go.tar.gz &&
     rm go.tar.gz; then
    print_success "Go installed successfully."
  else
    print_error "Failed to install Go."
    exit 1
  fi
}

# Function to set up Go environment
setup_go_environment() {
  start "Setting up Go environment..."
  if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    print_success "Go path added to ~/.bashrc."
  else
    print_success "Go path already exists in ~/.bashrc."
  fi

  # Export the updated PATH immediately for the current shell session
  export PATH=$PATH:/usr/local/go/bin

  # Verify Go installation
  start "Verify Go installation:"
  if go version; then
    print_success "Go is working as expected."
  else
    print_error "Go installation verification failed."
    exit 1
  fi
}

# Function to install Caddy, copy Caddyfile, and restart Caddy
install_caddy() {
  if ! command -v caddy &>/dev/null; then
    start "Installing Caddy..."

    # Add Caddy repository and install
    sudo apt update && sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo tee /usr/share/keyrings/caddy-keyring.asc >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/caddy-keyring.asc] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy-stable.list

    sudo apt update && sudo apt install -y caddy

    if command -v caddy &>/dev/null; then
      echo "✅ Caddy installed successfully."
    else
      echo "❌ Failed to install Caddy."
      exit 1
    fi
  else
    echo "✅ Caddy is already installed."
  fi

  # Copy Caddyfile to /etc/caddy/
  if [ -f "./Caddyfile" ]; then
    echo "📁 Copying Caddyfile to /etc/caddy/..."
    sudo cp ./Caddyfile /etc/caddy/Caddyfile
    sudo chown caddy:caddy /etc/caddy/Caddyfile
    sudo chmod 644 /etc/caddy/Caddyfile
    echo "✅ Caddyfile copied successfully."
  else
    echo "❌ Caddyfile not found in the current directory!"
    exit 1
  fi

  # Restart Caddy service
  echo "🔄 Restarting Caddy service..."
  sudo systemctl restart caddy

  if systemctl is-active --quiet caddy; then
    echo "✅ Caddy restarted successfully."
  else
    echo "❌ Caddy failed to restart!"
    exit 1
  fi
}




# Main script execution
check_root
install_curl
install_netstat
update_system_packages

# <----------nginx---------->
#install_nginx
#install_certbot
# <----------nginx---------->



install_caddy

install_docker
install_docker_compose
install_make
install_go
setup_go_environment

print_success "<--Setup completed successfully-->"
print_success "*************************************************"
print_success "**********SET UP SUCCESSFULLY COMPLETED**********"
print_success "*************************************************"
