# Eagle Email Platform - Infrastructure

This directory contains the production infrastructure configuration for the Eagle Email Platform.

## Files Overview

- `docker-compose.prod.yml` - Main production Docker Compose configuration
- `docker-compose.override.yml` - Development overrides (optional)
- `production.env` - Production environment variables template
- `mysql/conf.d/mysql.cnf` - MySQL configuration for production
- `DEPLOYMENT.md` - Complete deployment guide

## Quick Start

1. **Configure Environment**
   ```bash
   cp production.env .env
   # Edit .env with your actual values
   ```

2. **Deploy**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

3. **Initialize Laravel**
   ```bash
   docker-compose -f docker-compose.prod.yml exec backend php artisan key:generate
   docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force
   docker-compose -f docker-compose.prod.yml exec backend php artisan config:cache
   ```

## Services

- **nginx-proxy**: Reverse proxy with automatic SSL
- **letsencrypt**: SSL certificate management
- **database**: MySQL 8.0 database
- **redis**: Redis cache and session store
- **backend**: Laravel API application
- **worker**: Laravel queue worker
- **frontend**: Vue.js SPA application

## Domains

- `api.leython.com` - Laravel backend API
- `app.leython.com` - Vue.js frontend application

## Networking

- `proxy-network`: External-facing services (nginx-proxy, frontend, backend)
- `app-network`: Internal services (database, redis, backend, worker)

## Volumes

- `mysql-data`: Database persistence
- `redis-data`: Redis persistence
- `backend-storage`: Laravel storage
- `backend-logs`: Application logs
- `nginx-certs`: SSL certificates
- `nginx-vhost`: Nginx virtual hosts
- `nginx-html`: Nginx static files

## Security

- All services use `restart: unless-stopped`
- Non-root users where possible
- Security headers configured
- Rate limiting enabled
- SSL/TLS encryption

## Monitoring

- Health checks configured
- Log aggregation
- Resource monitoring
- Automatic restarts

For detailed deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).
