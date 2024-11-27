#!/bin/bash

# Define variables for directories and files
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
# NGINX_CONFIG="/etc/nginx/nginx.conf"

# Start the checklist
echo "Starting Nginx Verification Checklist..."

# 1. Check symlinks in sites-enabled
echo "Checking symlinks in $SITES_ENABLED..."
ls -al $SITES_ENABLED

# 2. Ensure symlinks exist
for site in "thyflightmenuassistant.com" "mutubackend.com"; do
    if [ ! -L "$SITES_ENABLED/$site" ]; then
        echo "Symlink for $site not found. Creating it..."
        sudo ln -s "$SITES_AVAILABLE/$site" "$SITES_ENABLED/$site" && \
        echo "Symlink for $site created." || \
        echo "Failed to create symlink for $site."
    else
        echo "Symlink for $site already exists."
    fi
done

# 3. Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Capture the output and warnings
NGINX_TEST_OUTPUT=$(sudo nginx -t 2>&1)

if echo "$NGINX_TEST_OUTPUT" | grep -q "syntax is ok"; then
    echo "Nginx syntax is OK."
else
    echo "Nginx syntax has errors! Please check the output above."
    exit 1
fi

if echo "$NGINX_TEST_OUTPUT" | grep -q "warn"; then
    echo "Warning detected in Nginx configuration:"
    echo "$NGINX_TEST_OUTPUT" | grep "warn"
else
    echo "No warnings detected in Nginx configuration."
fi

# 4. Restart Nginx
echo "Restarting Nginx service..."
sudo systemctl restart nginx && \
echo "Nginx restarted successfully." || \
echo "Failed to restart Nginx. Please check the systemctl logs."

# Final status
echo "Checklist completed."
