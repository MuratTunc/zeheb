#!/bin/bash
# usage:sudo ./setup_mutu_ssh.sh "<your-public-key>"
USERNAME="mutu"
PUBLIC_KEY="$1" # Pass the public key as an argument to the script

if [ -z "$PUBLIC_KEY" ]; then
  echo "Usage: sudo ./setup_mutu_ssh.sh '<public_ssh_key>'"
  exit 1
fi

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo ./setup_mutu_ssh.sh"
  exit 1
fi

# Create the .ssh directory if it doesn't exist
echo "Setting up .ssh directory for user '$USERNAME'..."
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Add the public key to authorized_keys
echo "Adding the public key to /home/$USERNAME/.ssh/authorized_keys..."
echo "$PUBLIC_KEY" >> /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys

echo "SSH key added successfully for user '$USERNAME'."