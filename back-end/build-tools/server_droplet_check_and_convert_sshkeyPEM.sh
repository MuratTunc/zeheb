#!/bin/bash

# Path to the private key file
KEY_FILE="$HOME/.ssh/id_rsa"

# Check if the private key file exists
if [[ ! -f "$KEY_FILE" ]]; then
    echo "Error: Private key file not found at $KEY_FILE"
    exit 1
fi

# Check if the key is in PEM format
if grep -q "BEGIN RSA PRIVATE KEY" "$KEY_FILE"; then
    echo "The private key is already in PEM format."
else
    echo "The private key is not in PEM format. Converting..."
    ssh-keygen -p -m PEM -f "$KEY_FILE" -q -N "" # Converts to PEM without passphrase
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to convert the private key to PEM format."
        exit 1
    fi
    echo "Successfully converted the private key to PEM format."
fi

# Print the private key to the console
echo "Private key content:"
cat "$KEY_FILE"

exit 0