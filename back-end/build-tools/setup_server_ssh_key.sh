#!/bin/bash

# Variables
REMOTE_USER="mutu"
REMOTE_HOST="your.server.ip.or.domain"
REMOTE_HOME="/home/$REMOTE_USER"
LOCAL_SSH_KEY="$HOME/.ssh/id_rsa.pub"
AUTHORIZED_KEYS="$REMOTE_HOME/.ssh/authorized_keys"
EMAIL="your_email@example.com" # Static email address

# Step 1: Check if the local SSH key exists
if [ ! -f "$LOCAL_SSH_KEY" ]; then
  echo "Local SSH public key not found. Generating a new SSH key pair..."
  ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$HOME/.ssh/id_rsa" -N ""
  echo "SSH key pair generated."
else
  echo "Local SSH public key exists."
fi

# Step 2: Ensure the remote .ssh directory exists
echo "Ensuring $REMOTE_HOME/.ssh exists on the remote server..."
ssh "$REMOTE_USER@$REMOTE_HOST" "if [ ! -d $REMOTE_HOME/.ssh ]; then mkdir -p $REMOTE_HOME/.ssh && chmod 700 $REMOTE_HOME/.ssh; fi"

# Step 3: Copy the public key to the remote server
echo "Copying SSH public key to the remote server..."
if ssh-copy-id -i "$LOCAL_SSH_KEY" "$REMOTE_USER@$REMOTE_HOST"; then
  echo "SSH key successfully added to $REMOTE_USER@$REMOTE_HOST."
else
  echo "Failed to copy the SSH key. Please check your connection and credentials."
  exit 1
fi

# Step 4: Ensure permissions are set correctly on the remote server
echo "Setting permissions on the remote server..."
ssh "$REMOTE_USER@$REMOTE_HOST" "chmod 600 $AUTHORIZED_KEYS && chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_HOME/.ssh"

echo "SSH setup complete. You can now log in to $REMOTE_USER@$REMOTE_HOST without a password."
