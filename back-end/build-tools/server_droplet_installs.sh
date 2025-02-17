#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() { echo -e "✅✅✅ ${GREEN}$1${NC}"; }
print_error() { echo -e "❌❌❌ ${RED}$1${NC}"; }

# Ensure script runs as root
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root. Use sudo ./server_droplet_installs.sh"
  exit 1
fi

# Function to install a package if not already installed
install_package() {
  local package_name=$1
  local install_command=$2

  if ! command -v "$package_name" &>/dev/null; then
    echo "Installing $package_name..."
    if apt install -y "$install_command"; then
      print_success "$package_name installed successfully."
    else
      print_error "Failed to install $package_name."
      exit 1
    fi
  else
    print_success "$package_name is already installed."
  fi
}

# Install Docker
install_docker() {
  if ! command -v docker &>/dev/null; then
    echo "Installing Docker..."
    if apt install -y ca-certificates curl gnupg lsb-release &&
       mkdir -p /etc/apt/keyrings &&
       curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
       echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&
       apt update &&
       apt install -y docker-ce docker-ce-cli containerd.io; then
      print_success "Docker installed successfully."
    else
      print_error "Failed to install Docker."
      exit 1
    fi
  else
    print_success "Docker is already installed."
  fi
}

# Install Docker Compose
install_docker_compose() {
  if ! command -v docker-compose &>/dev/null; then
    echo "Installing Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    if curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
       chmod +x /usr/local/bin/docker-compose; then
      print_success "Docker Compose installed successfully."
    else
      print_error "Failed to install Docker Compose."
      exit 1
    fi
  else
    print_success "Docker Compose is already installed."
  fi
}

# Install latest Go version
install_go() {
  echo "Installing latest Go version..."
  GO_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+\.linux-amd64\.tar\.gz' | head -n 1)
  GO_VERSION_URL="https://go.dev/dl/${GO_VERSION}"

  if curl -fsSL "$GO_VERSION_URL" -o go.tar.gz &&
     tar -C /usr/local -xzf go.tar.gz &&
     rm go.tar.gz; then
    print_success "Go installed successfully."
  else
    print_error "Failed to install Go."
    exit 1
  fi
}

# Configure Go environment
setup_go_environment() {
  if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    print_success "Go path added to ~/.bashrc."
  fi
  export PATH=$PATH:/usr/local/go/bin

  # Verify Go installation
  if go version; then
    print_success "Go installation verified."
  else
    print_error "Go installation verification failed."
    exit 1
  fi
}

# Check running Docker containers
check_docker_containers() {
  echo "Checking running Docker containers..."
  if docker ps -q | grep -q .; then
    print_success "The following Docker containers are running:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
  else
    print_error "No Docker containers are currently running."
  fi
}

# Check active Nginx ports
check_nginx_ports() {
  echo "Checking Nginx active ports..."
  if netstat -tuln | grep -q ":80\|:443"; then
    print_success "Nginx is actively listening on the following ports:"
    netstat -tuln | grep -E "Proto|:80|:443"
  else
    print_error "Nginx is not actively listening on ports 80 or 443."
  fi
}

# Update system packages once before installations
echo "Updating package list..."
if apt update && apt upgrade -y; then
  print_success "System packages updated successfully."
else
  print_error "Failed to update system packages."
  exit 1
fi

# Install required packages
install_package curl curl
install_package netstat net-tools
install_package npm "nodejs npm"
install_package nginx nginx
install_package certbot "certbot python3-certbot-nginx"
install_package make make

# Call modular functions
install_docker
install_docker_compose
install_go
setup_go_environment
check_docker_containers
check_nginx_ports


print_success "*************************************************"
print_success "**********SET UP SUCCESSFULLY COMPLETED**********"
print_success "*************************************************"
