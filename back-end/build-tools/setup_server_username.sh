#!/bin/bash

USERNAME="mutu"

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo ./setup_mutu.sh"
  exit 1
fi

# Check if the user exists
if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists. Skipping user creation."
else
  echo "Creating user '$USERNAME'..."
  useradd -m -s /bin/bash "$USERNAME"
  
  # Set password for the user
  echo "$USERNAME:$USERNAME" | chpasswd
  echo "Password set to '$USERNAME'. Please change it after setup."
fi

# Configure .ssh directory for the user
echo "Setting up .ssh directory for '$USERNAME'..."
mkdir -p /home/$USERNAME/.ssh
chmod 0700 /home/$USERNAME/.ssh/
cp -Rfv /root/.ssh /home/$USERNAME/
chown -Rfv $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Correct ownership for the user's home directory
chown -R $USERNAME:$USERNAME /home/$USERNAME/

# Add user to the sudo group
echo "Adding '$USERNAME' to the sudo group..."
gpasswd -a $USERNAME sudo

# Configure sudoers file for passwordless sudo
echo "Configuring passwordless sudo for '$USERNAME'..."
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

# Restart SSH service
echo "Restarting SSH service..."
service ssh restart

# Set the default shell for the user
echo "Setting default shell for '$USERNAME'..."
usermod -s /bin/bash $USERNAME

echo "Setup completed for user '$USERNAME'. Switching to the new user session..."

# Switch to the new user
su - $USERNAME
