server {
    listen 443 ssl; # SSL enabled for secure connection
    server_name zehebfind.com www.zehebfind.com;

    # Frontend - Serving the React app from /var/www/html/build
    location / {
        root /var/www/html/build;
        index index.html;
        try_files $uri /index.html;  # Fallback to index.html for React routing
    }

    # API Proxy - Proxying requests to the backend service on port 8000
    location /api/ {
        proxy_pass http://localhost:8000/;  # Points to your backend service running on port 8000
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # SSL Configuration - Managed by Certbot (assuming SSL is configured with Certbot)
    ssl_certificate /etc/letsencrypt/live/zehebfind.com/fullchain.pem; # Managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/zehebfind.com/privkey.pem; # Managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # Managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # Managed by Certbot
}

server {
    if ($host = www.zehebfind.com) {
        return 301 https://$host$request_uri;
    }

    if ($host = zehebfind.com) {
        return 301 https://$host$request_uri;
    }

    listen 80;
    server_name zehebfind.com www.zehebfind.com;
    return 404;
}
