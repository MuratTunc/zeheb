#!/bin/bash

# Get the current directory where this script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Find all `.sh` scripts in the current directory and give them executable permissions
for SCRIPT in "$SCRIPT_DIR"/*.sh; do
  if [ -f "$SCRIPT" ]; then
    echo "Giving executable permission to $SCRIPT..."
    chmod +x "$SCRIPT"
  else
    echo "No shell scripts found in $SCRIPT_DIR."
    exit 1
  fi
done

echo "All shell scripts in $SCRIPT_DIR have been updated with executable permissions."
