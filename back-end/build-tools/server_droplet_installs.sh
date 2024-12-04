#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root. Use sudo ./setup_server_installs.sh"
  exit 1
fi

# Install curl if not already installed
if ! command -v curl &>/dev/null; then
  echo "curl not found, installing..."
  if apt install -y curl; then
    print_success "curl installed successfully."
  else
    print_error "Failed to install curl."
  fi
else
  print_success "curl is already installed."
fi

# Install netstat (part of net-tools) if not already installed
if ! command -v netstat &>/dev/null; then
  echo "netstat not found, installing net-tools..."
  if apt install -y net-tools; then
    print_success "net-tools installed successfully."
  else
    print_error "Failed to install net-tools."
  fi
else
  print_success "netstat is already installed."
fi

# Install npm if not already installed
if ! command -v npm &>/dev/null; then
  echo "npm not found, installing Node.js and npm..."
  if apt update && apt install -y nodejs npm; then
    print_success "Node.js and npm installed successfully."
  else
    print_error "Failed to install Node.js and npm."
  fi
else
  print_success "npm is already installed."
fi

# Update system packages
echo "Updating package list..."
if apt update && apt upgrade -y; then
  print_success "System packages updated successfully."
else
  print_error "Failed to update system packages."
fi

# Check and install Nginx
if ! nginx -v &>/dev/null; then
  echo "Installing Nginx..."
  if apt install -y nginx && systemctl enable nginx && systemctl start nginx; then
    print_success "Nginx installed and started successfully."
  else
    print_error "Failed to install or start Nginx."
  fi
else
  print_success "Nginx is already installed."
fi

# Check and install Docker
if ! docker --version &>/dev/null; then
  echo "Installing Docker..."
  if apt install -y ca-certificates curl gnupg lsb-release &&
     mkdir -p /etc/apt/keyrings &&
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
     echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&
     apt update &&
     apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    print_success "Docker installed successfully."
  else
    print_error "Failed to install Docker."
  fi
else
  print_success "Docker is already installed."
fi

# Check and install Certbot
if ! certbot --version &>/dev/null; then
  echo "Installing Certbot..."
  if apt install -y certbot python3-certbot-nginx; then
    print_success "Certbot installed successfully."
  else
    print_error "Failed to install Certbot."
  fi
else
  print_success "Certbot is already installed."
fi

# Install Make
echo "Installing Make..."
if apt install -y make; then
  print_success "Make installed successfully."
else
  print_error "Failed to install Make."
fi

# Install the latest Go version
echo "Installing the latest version of Go..."
GO_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+\.linux-amd64\.tar\.gz' | head -n 1)
GO_VERSION_URL="https://go.dev/dl/${GO_VERSION}"

if curl -fsSL "$GO_VERSION_URL" -o go.tar.gz &&
   sudo tar -C /usr/local -xzf go.tar.gz &&
   rm go.tar.gz; then
  print_success "Go installed successfully."
else
  print_error "Failed to install Go."
fi

# Add Go to PATH
echo "Setting up Go environment..."
if echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc && source ~/.bashrc; then
  print_success "Go environment set up successfully."
else
  print_error "Failed to set up Go environment."
fi

# Check the installed Go version
echo "Go version:"
if go version; then
  print_success "Go is working as expected."
else
  print_error "Go installation verification failed."
fi

# Display running Docker containers
echo "Checking running Docker containers..."
if docker ps -q | grep -q .; then
  print_success "The following Docker containers are running:"
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
else
  print_error "No Docker containers are currently running."
fi

# Display Nginx active ports
echo "Checking Nginx active ports..."
if netstat -tuln | grep -q ":80\|:443"; then
  print_success "Nginx is actively listening on the following ports:"
  netstat -tuln | grep -E "Proto|:80|:443"
else
  print_error "Nginx is not actively listening on ports 80 or 443."
fi

print_success "Setup completed successfully!"
