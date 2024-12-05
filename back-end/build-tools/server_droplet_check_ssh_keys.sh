#!/bin/bash

# Function to check if a key is in PEM format
check_pem_format() {
  local key_path=$1

  # PEM keys start with "-----BEGIN OPENSSH PRIVATE KEY-----" or "-----BEGIN RSA PRIVATE KEY-----"
  if grep -q "BEGIN OPENSSH PRIVATE KEY" "$key_path"; then
    echo "$key_path is already in PEM format (OpenSSH)."
  elif grep -q "BEGIN RSA PRIVATE KEY" "$key_path"; then
    echo "$key_path is already in PEM format (RSA)."
  else
    echo "$key_path is NOT in PEM format. Converting to PEM format..."
    local backup_path="${key_path}.backup"
    cp "$key_path" "$backup_path"
    chmod 600 "$backup_path" # Secure the backup key

    # Convert to PEM format using OpenSSH tools
    ssh-keygen -p -m PEM -f "$key_path" -N "" || {
      echo "Failed to convert $key_path to PEM format."
      return 1
    }
    echo "$key_path has been converted to PEM format. Original key backed up at $backup_path."
  fi
}

# List all private SSH keys in the default ~/.ssh directory
echo "Checking SSH keys in ~/.ssh..."
for key_file in ~/.ssh/id_*; do
  if [[ -f "$key_file" && "$key_file" != *.pub ]]; then
    echo "Private key found: $key_file"

    # Ensure proper file permissions
    echo "Setting correct permissions for $key_file..."
    chmod 600 "$key_file"

    # Check if the key is in PEM format and convert if necessary
    check_pem_format "$key_file"
  fi
done

# Check if the SSH agent is running and healthy
echo "Checking SSH agent status..."
if ! ssh-add -l >/dev/null 2>&1; then
  echo "SSH agent is not running. Starting it..."
  eval "$(ssh-agent -s)"
else
  echo "SSH agent is running."
fi

# Add all private keys to the SSH agent
echo "Adding private keys to the SSH agent..."
for key_file in ~/.ssh/id_*; do
  if [[ -f "$key_file" && "$key_file" != *.pub ]]; then
    ssh-add "$key_file" || echo "Failed to add $key_file to the SSH agent."
  fi
done

# List currently loaded keys
echo "Currently loaded keys in the SSH agent:"
ssh-add -l

# Verify connection to GitHub
echo "Verifying connection to GitHub..."
ssh -T git@github.com || echo "Failed to connect to GitHub. Check your SSH configuration."

# Print private and public keys to the terminal (Be cautious in production environments)
echo "Printing private and public keys..."

# Loop through all private keys and print both private and public keys
for key_file in ~/.ssh/id_*; do
  if [[ -f "$key_file" && "$key_file" != *.pub ]]; then
    echo "Private key content ($key_file):"
    cat "$key_file"

    # Check for corresponding public key and print it
    public_key="${key_file}.pub"
    if [[ -f "$public_key" ]]; then
      echo "Public key content ($public_key):"
      cat "$public_key"
    else
      echo "No public key found for $key_file."
    fi
  fi
done

echo "SSH key check and configuration completed."
