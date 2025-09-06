#!/bin/bash

# Fix frontend build issues by updating Dockerfile

echo "🔧 Fixing frontend build issues..."

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

echo "✅ Updated Dockerfile with correct dependencies"

# Go back to infra directory
cd /opt/eagle-platform/infra

echo "🚀 Deploying with fixed frontend..."

# Deploy
docker compose -f docker-compose.prod.yml up -d --build

echo "✅ Deployment completed!"
echo ""
echo "🔍 Check status:"
docker compose -f docker-compose.prod.yml ps
