#!/bin/bash

# Define variables for server and script paths
SERVER_IP="64.23.150.141"            # Replace with your server IP
SERVER_USER="root"                    # Assuming root user
LOCAL_SCRIPT_PATH="./server_droplet_newuser.sh"  # Local path to the script
REMOTE_SCRIPT_PATH="/root/server_droplet_newuser.sh"  # Remote path for the script

# 1. Copy the server_droplet_newuser.sh script to the server as the root user
echo "Copying the script to the server droplet..."
scp "$LOCAL_SCRIPT_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_SCRIPT_PATH"

# Check if the script copied successfully
if [ $? -ne 0 ]; then
  echo "Failed to copy the script to the server. Exiting..."
  exit 1
fi

# 2. Give execution permissions to the script on the server
echo "Setting execution permissions for the script on the server..."
ssh "$SERVER_USER@$SERVER_IP" "chmod +x $REMOTE_SCRIPT_PATH"

# Check if permissions were set correctly
if [ $? -ne 0 ]; then
  echo "Failed to set execution permissions on the server. Exiting..."
  exit 1
fi

# 3. Run the script on the server as the root user
echo "Running the script on the server droplet..."
ssh "$SERVER_USER@$SERVER_IP" "bash $REMOTE_SCRIPT_PATH"

# Check if the script ran successfully
if [ $? -eq 0 ]; then
  echo "New user setup script executed successfully on the server!"
else
  echo "Failed to execute the script on the server."
  exit 1
fi
