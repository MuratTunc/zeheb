#!/bin/bash

# Load .env file

DOMAIN_NAME=zehebfind
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_NGINX_CONF_FILE="$SCRIPT_DIR/$DOMAIN_NAME.conf"
LOCAL_ENV_FILE="$(dirname "$0")/.env"  # Path to the .env file (same directory as this script)

echo $LOCAL_NGINX_CONF_FILE