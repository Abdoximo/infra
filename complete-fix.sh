#!/bin/bash

# Complete fix for Eagle Email Platform deployment issues

set -e

echo "🔧 Starting complete fix for Eagle Email Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    print_error "Please run this script from the infra directory"
    exit 1
fi

print_status "Fixing frontend Dockerfile..."

# Navigate to frontend directory
cd /opt/eagle-platform/frontend

# Create corrected Dockerfile
cat > Dockerfile << 'EOF'
# Multi-stage build for Vue.js production
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev dependencies for build)
RUN npm ci --silent

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built assets from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create nginx user and set permissions
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create nginx.conf
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Handle Vue.js SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
    }

    # Cache HTML files for a short time
    location ~* \.html$ {
        expires 1h;
        add_header Cache-Control "public";
    }

    # API proxy to backend (if needed for development)
    location /api/ {
        proxy_pass http://backend:80/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to source maps in production
    location ~* \.map$ {
        deny all;
    }
}
EOF

print_success "Created Dockerfile and nginx.conf in frontend directory"

# Go back to infra directory
cd /opt/eagle-platform/infra

print_status "Fixing docker-compose.prod.yml..."

# Fix docker-compose.prod.yml
sed -i 's|../eagle|../backend|g' docker-compose.prod.yml
sed -i '/^version:/d' docker-compose.prod.yml

print_success "Fixed docker-compose.prod.yml"

print_status "Stopping any existing containers..."

# Stop existing containers
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

print_status "Building and starting services..."

# Build and start services
docker compose -f docker-compose.prod.yml up -d --build

print_status "Waiting for services to be ready..."
sleep 15

# Check if services are running
print_status "Checking service status..."
docker compose -f docker-compose.prod.yml ps

# Initialize Laravel application
print_status "Initializing Laravel application..."

# Generate application key
docker compose -f docker-compose.prod.yml exec -T backend php artisan key:generate --force

# Run database migrations
docker compose -f docker-compose.prod.yml exec -T backend php artisan migrate --force

# Cache configuration for production
docker compose -f docker-compose.prod.yml exec -T backend php artisan config:cache
docker compose -f docker-compose.prod.yml exec -T backend php artisan route:cache
docker compose -f docker-compose.prod.yml exec -T backend php artisan view:cache

# Create storage link
docker compose -f docker-compose.prod.yml exec -T backend php artisan storage:link

# Set proper permissions
docker compose -f docker-compose.prod.yml exec -T backend chown -R www-data:www-data /var/www/html/storage
docker compose -f docker-compose.prod.yml exec -T backend chmod -R 755 /var/www/html/storage

print_success "Eagle Email Platform deployment completed successfully!"
echo ""
echo "🌐 Your application is available at:"
echo "   Frontend: https://app.leython.com"
echo "   Backend API: https://api.leython.com"
echo ""
echo "📊 To view logs:"
echo "   docker compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🔍 To check service health:"
echo "   docker compose -f docker-compose.prod.yml ps"
