#!/bin/bash

# Parameters
SERVER_IP="64.23.150.141"  # Replace with your server IP
USERNAME="mutu"  # Predefined username, change this as needed

# Start the SSH agent
echo "Starting SSH agent..."
eval "$(ssh-agent -s)"

# Copy the private SSH key to the server
echo "Copying the private SSH key to the server droplet..."
scp ~/.ssh/id_rsa "$USERNAME@$SERVER_IP:/home/$USERNAME/.ssh/id_rsa"

# Set correct permissions for the private key on the server
echo "Setting correct permissions for the private key..."
ssh "$USERNAME@$SERVER_IP" "chmod 600 /home/$USERNAME/.ssh/id_rsa"

# Add the private key to the SSH agent
echo "Adding the private key to the SSH agent..."
ssh "$USERNAME@$SERVER_IP" "ssh-add /home/$USERNAME/.ssh/id_rsa"

# Test the SSH connection to GitHub
echo "Testing the SSH connection to GitHub..."
ssh "$USERNAME@$SERVER_IP" "ssh -T git@github.com"
