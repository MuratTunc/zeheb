#!/bin/bash
# usage:sudo ./setup_mutu_ssh.sh "<your-public-key>"
USERNAME="mutu"
PUBLIC_KEY="$1" # Pass the public key as an argument to the script

# Path to your private key (update if necessary)
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"

if [ -z "$PUBLIC_KEY" ]; then
  echo "Usage: sudo ./server_droplet_ssh.sh'<public_ssh_key>'"
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

# Step 1: Check if the private key exists. If not, generate a new one.
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
  echo "Private key not found. Generating new SSH key pair..."
  ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N ""  # Empty passphrase
  if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSH key."
    exit 1
  fi
  echo "New SSH key pair generated."
else
  echo "Private key found. Skipping key generation."
fi

# Step 2: Start the SSH Agent
echo "Starting SSH agent..."
eval "$(ssh-agent -s)"

# Step 3: Add the private key to the SSH agent
echo "Adding private key to SSH agent..."
ssh-add "$PRIVATE_KEY_PATH"

# Step 4: Verify that the key is loaded
echo "Verifying the key is loaded..."
ssh-add -l
if [[ $? -ne 0 ]]; then
  echo "Error: Private key was not loaded successfully."
  exit 1
fi

# Step 5: Test SSH connection to GitHub
echo "Testing SSH connection to GitHub..."
ssh -T git@github.com
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to authenticate with GitHub."
  exit 1
fi

echo "SSH setup and authentication with GitHub successful!"
