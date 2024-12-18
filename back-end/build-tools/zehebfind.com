server {
    listen 80;
    server_name zehebfind.com www.zehebfind.com;

    root /var/www/html/build;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg|mp4|webm|ogv|webp)$ {
        expires 6M;
        access_log off;
        add_header Cache-Control "public";
    }
}