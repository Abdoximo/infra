#!/bin/bash

# Eagle Email Platform Deployment Script
# Usage: ./deploy.sh [environment]
# Environment: production (default) or development

set -e

ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.prod.yml"

echo "🚀 Deploying Eagle Email Platform ($ENVIRONMENT environment)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from template..."
    if [ -f "production.env" ]; then
        cp production.env .env
        echo "📝 Please edit .env file with your actual values before running again."
        exit 1
    else
        echo "❌ production.env template not found. Please create .env file manually."
        exit 1
    fi
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

echo "📦 Building and starting services..."

# Fix frontend Dockerfile if needed
if [ ! -f "../frontend/Dockerfile" ]; then
    echo "🔧 Creating missing frontend Dockerfile..."
    cd ../frontend
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
    cd ../infra
fi

# Build and start services
docker-compose -f $COMPOSE_FILE up -d --build

echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose -f $COMPOSE_FILE ps

# Initialize Laravel application
echo "🔧 Initializing Laravel application..."

# Generate app key if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
    echo "🔑 Generating application key..."
    docker-compose -f $COMPOSE_FILE exec -T backend php artisan key:generate --force
fi

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f $COMPOSE_FILE exec -T backend php artisan migrate --force

# Cache configuration
echo "⚡ Caching configuration..."
docker-compose -f $COMPOSE_FILE exec -T backend php artisan config:cache
docker-compose -f $COMPOSE_FILE exec -T backend php artisan route:cache
docker-compose -f $COMPOSE_FILE exec -T backend php artisan view:cache

# Create storage link
echo "🔗 Creating storage link..."
docker-compose -f $COMPOSE_FILE exec -T backend php artisan storage:link

# Set permissions
echo "🔐 Setting permissions..."
docker-compose -f $COMPOSE_FILE exec -T backend chown -R www-data:www-data /var/www/html/storage
docker-compose -f $COMPOSE_FILE exec -T backend chmod -R 755 /var/www/html/storage

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Your application is available at:"
echo "   Frontend: https://app.leython.com"
echo "   Backend API: https://api.leython.com"
echo ""
echo "📊 To view logs:"
echo "   docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "🛠️  To access backend container:"
echo "   docker-compose -f $COMPOSE_FILE exec backend bash"
echo ""
echo "🔍 To check service health:"
echo "   docker-compose -f $COMPOSE_FILE ps"
