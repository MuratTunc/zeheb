#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW="\033[0;33m"
RESET="\033[0m"

# Function to display success messages
start() {
  echo -e "🔄🔄🔄 ${YELLOW}$1${RESET}"
}

print_success() { echo -e "✅✅✅ ${GREEN}$1${NC}"; }
print_error() { echo -e "❌❌❌ ${RED}$1${NC}"; }


# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root. Use sudo ./setup_server_installs.sh"
  exit 1
fi

# Install curl if not already installed
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

# Install netstat (part of net-tools) if not already installed
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


# Update system packages
echo "Updating package list..."
if apt update && apt upgrade -y; then
  print_success "System packages updated successfully."
else
  print_error "Failed to update system packages."
fi


# Check and install Docker
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

# Install Docker Compose stand-alone binary
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

# Check and install Certbot
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

# Install Make
start "Installing Make..."
if apt install -y make; then
  print_success "Make installed successfully."
else
  print_error "Failed to install Make."
fi

# Install the latest Go version
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

# Add Go to PATH if not already added
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
start "Go version:"
if go version; then
  print_success "Go is working as expected."
else
  print_error "Go installation verification failed."
  exit 1
fi


# Display Nginx active ports
start "Checking Nginx active ports..."
if netstat -tuln | grep -q ":80\|:443"; then
  print_success "Nginx is actively listening on the following ports:"
  netstat -tuln | grep -E "Proto|:80|:443"
else
  print_error "Nginx is not actively listening on ports 80 or 443."
fi

print_success "<--Setup completed successfully-->"


print_success "*************************************************"
print_success "**********SET UP SUCCESSFULLY COMPLETED**********"
print_success "*************************************************"
