#!/bin/bash

# Define the .env file location
ENV_FILE=".env"

# Read the domain name from the .env file
DOMAIN_NAME=$(awk -F= '/^DOMAIN_NAME=/ {print $2}' "$ENV_FILE")

# Extract nginx configurations between the start and end markers
CONFIG_BLOCK=$(awk '/# nginx configurations start/,/# nginx configurations end/' "$ENV_FILE")

# Extract services and ports from the extracted block
SERVICE_1=$(echo "$CONFIG_BLOCK" | awk -F= '/^SERVICE_1=/ {print $2}')
SERVICE_1_PORT=$(echo "$CONFIG_BLOCK" | awk -F= '/^SERVICE_1_PORT=/ {print $2}')
SERVICE_2=$(echo "$CONFIG_BLOCK" | awk -F= '/^SERVICE_2=/ {print $2}')
SERVICE_2_PORT=$(echo "$CONFIG_BLOCK" | awk -F= '/^SERVICE_2_PORT=/ {print $2}')

# Ensure DOMAIN_NAME is not empty
if [[ -z "$DOMAIN_NAME" ]]; then
    echo "Error: DOMAIN_NAME not found in $ENV_FILE"
    exit 1
fi

# Define the output Nginx config filename
OUTPUT_FILE="$DOMAIN_NAME"

# Generate the Nginx configuration file
cat > "$OUTPUT_FILE" <<EOL
server {
    listen 80;
    server_name www.$DOMAIN_NAME.com;
    return 301 http://$DOMAIN_NAME.com\$request_uri;  # ✅ Redirect www to non-www
}

server {
    listen 80;
    server_name $DOMAIN_NAME.com;

    root /var/www/html/build;
    index index.html;
    
    location / {
        try_files \$uri /index.html;
    }

    location /.well-known/acme-challenge/ {  # ✅ Add this block
        root /var/www/html;
        allow all;
    }

    location /$SERVICE_1/ {
        proxy_pass http://127.0.0.1:$SERVICE_1_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /$SERVICE_2/ {
        proxy_pass http://127.0.0.1:$SERVICE_2_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

echo "Nginx configuration file '$OUTPUT_FILE' has been created successfully!"
