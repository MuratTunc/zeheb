#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo ./setup.sh"
  exit 1
fi

# Install curl if not already installed
if ! command -v curl &>/dev/null; then
  echo "curl not found, installing..."
  apt install -y curl
else
  echo "curl is already installed."
fi

# Install netstat (part of net-tools) if not already installed
if ! command -v netstat &>/dev/null; then
  echo "netstat not found, installing net-tools..."
  apt install -y net-tools
else
  echo "netstat is already installed."
fi

# Install npm if not already installed
if ! command -v npm &>/dev/null; then
  echo "npm not found, installing Node.js and npm..."
  apt update
  apt install -y nodejs npm
else
  echo "npm is already installed."
fi

# Update system packages
echo "Updating package list..."
apt update && apt upgrade -y

# Check and install Nginx
if ! nginx -v &>/dev/null; then
  echo "Installing Nginx..."
  apt install nginx -y
  systemctl enable nginx
  systemctl start nginx
else
  echo "Nginx is already installed. Skipping installation."
fi

# Check and install Docker
if ! docker --version &>/dev/null; then
  echo "Installing Docker..."
  apt install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker installed."
else
  echo "Docker is already installed. Skipping installation."
fi

# Check and install Certbot
if ! certbot --version &>/dev/null; then
  echo "Installing Certbot..."
  apt install -y certbot python3-certbot-nginx
else
  echo "Certbot is already installed. Skipping installation."
fi

# Install Make
echo "Installing Make..."
apt install -y make

# Install the latest Go version
echo "Installing the latest version of Go..."
GO_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+-linux-amd64' | head -n 1)
GO_VERSION_URL="https://go.dev/dl/${GO_VERSION}.tar.gz"

# Download and extract the Go tar file
curl -fsSL "$GO_VERSION_URL" -o go.tar.gz
tar -C /usr/local -xzf go.tar.gz
rm go.tar.gz

# Add Go to PATH
echo "Setting up Go environment..."
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Check the installed Go version
echo "Go version:"
go version

# Display running Docker containers
echo "Checking running Docker containers..."
if docker ps -q | grep -q .; then
  echo "The following Docker containers are running:"
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
else
  echo "No Docker containers are currently running."
fi

# Display Nginx active ports
echo "Checking Nginx active ports..."
if netstat -tuln | grep -q ":80\|:443"; then
  netstat -tuln | grep -E "Proto|:80|:443"
else
  echo "Nginx is not actively listening on ports 80 or 443."
fi

echo "Setup completed."
