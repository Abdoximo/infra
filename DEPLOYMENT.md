# Eagle Email Platform - Production Deployment Guide

This guide will help you deploy the Eagle Email Platform (Laravel backend + Vue.js frontend) on your server alongside your existing Postal email server.

## Prerequisites

- Docker and Docker Compose installed on your server
- Domain name (leython.com) with DNS configured
- Existing Postal server running (don't break it!)
- Git access to your repository
- SSL certificate management (handled automatically by nginx-proxy)

## Server Requirements

- **CPU**: 2+ cores
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 50GB+ SSD
- **OS**: Ubuntu 20.04+ or similar Linux distribution

## Quick Start

### 1. Clone Repository

```bash
# Clone your repository
git clone <your-repo-url> /opt/eagle-platform
cd /opt/eagle-platform

# Or if you already have the code locally, copy it to the server
scp -r /path/to/eagle-platform user@your-server:/opt/
```

### 2. Configure Environment

```bash
# Navigate to infra directory
cd infra

# Copy and edit the production environment file
cp production.env .env

# Edit the environment variables
nano .env
```

**Important Environment Variables to Configure:**

```bash
# Generate a secure app key (run this on the server)
openssl rand -base64 32

# Set your database passwords
DB_PASSWORD=your_secure_database_password
DB_ROOT_PASSWORD=your_secure_root_password

# Set your Redis password
REDIS_PASSWORD=your_secure_redis_password

# Configure Postal connection
MAIL_USERNAME=your_postal_username
MAIL_PASSWORD=your_postal_password

# Set your domain
APP_URL=https://api.leython.com
```

### 3. Deploy with Docker Compose

```bash
# Start all services
docker-compose -f docker-compose.prod.yml up -d --build

# Check if all containers are running
docker-compose -f docker-compose.prod.yml ps
```

### 4. Initialize Laravel Application

```bash
# Generate application key
docker-compose -f docker-compose.prod.yml exec backend php artisan key:generate

# Run database migrations
docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force

# Cache configuration for production
docker-compose -f docker-compose.prod.yml exec backend php artisan config:cache

# Cache routes
docker-compose -f docker-compose.prod.yml exec backend php artisan route:cache

# Cache views
docker-compose -f docker-compose.prod.yml exec backend php artisan view:cache

# Create storage link
docker-compose -f docker-compose.prod.yml exec backend php artisan storage:link

# Seed initial data (optional)
docker-compose -f docker-compose.prod.yml exec backend php artisan db:seed
```

### 5. Configure Frontend Environment

The frontend will automatically connect to the backend via the environment variables set in the docker-compose file:

- `VUE_APP_API_BASE_URL=https://api.leython.com`
- `VUE_APP_APP_URL=https://app.leython.com`

## DNS Configuration

Configure your DNS records to point to your server:

```
A    api.leython.com    -> YOUR_SERVER_IP
A    app.leython.com    -> YOUR_SERVER_IP
A    leython.com        -> YOUR_SERVER_IP
```

## SSL Certificates

SSL certificates are automatically managed by nginx-proxy and Let's Encrypt. The first time you access your domains, certificates will be automatically generated.

## Service Management

### Start Services
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f worker
```

### Update Application
```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build

# Run migrations if needed
docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check if all services are healthy
docker-compose -f docker-compose.prod.yml ps

# Check specific service health
curl -f http://localhost/health  # Frontend
curl -f http://localhost/api/health  # Backend (if you have a health endpoint)
```

### Database Backup

```bash
# Create database backup
docker-compose -f docker-compose.prod.yml exec database mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_DATABASE} > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database backup
docker-compose -f docker-compose.prod.yml exec -T database mysql -u root -p${DB_ROOT_PASSWORD} ${DB_DATABASE} < backup_file.sql
```

### Log Rotation

Logs are stored in Docker volumes. To prevent disk space issues:

```bash
# Clean up old logs
docker system prune -f

# View log sizes
docker system df
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   - Check if nginx-proxy is running
   - Verify DNS is pointing to your server
   - Check Let's Encrypt logs: `docker-compose logs letsencrypt`

2. **Database Connection Issues**
   - Check if database container is running
   - Verify database credentials in .env file
   - Check database logs: `docker-compose logs database`

3. **Frontend Not Loading**
   - Check if frontend container is running
   - Verify nginx-proxy configuration
   - Check frontend logs: `docker-compose logs frontend`

4. **Backend API Issues**
   - Check if backend container is running
   - Verify Laravel configuration
   - Check backend logs: `docker-compose logs backend`

### Useful Commands

```bash
# Access backend container
docker-compose -f docker-compose.prod.yml exec backend bash

# Access database
docker-compose -f docker-compose.prod.yml exec database mysql -u root -p

# Check container resource usage
docker stats

# View all volumes
docker volume ls

# Clean up unused resources
docker system prune -a
```

## Security Considerations

1. **Firewall Configuration**
   - Only allow ports 80, 443, and 22 (SSH)
   - Block all other ports

2. **Database Security**
   - Use strong passwords
   - Regularly update passwords
   - Enable SSL for database connections

3. **Application Security**
   - Keep Docker images updated
   - Regularly update dependencies
   - Monitor logs for suspicious activity

4. **SSL/TLS**
   - Certificates are automatically renewed
   - Monitor certificate expiration

## Performance Optimization

1. **Database Optimization**
   - Monitor slow queries
   - Optimize database indexes
   - Regular maintenance

2. **Caching**
   - Redis is configured for caching
   - Monitor cache hit rates
   - Adjust cache settings as needed

3. **Resource Monitoring**
   - Monitor CPU and memory usage
   - Scale resources as needed
   - Set up monitoring alerts

## Backup Strategy

1. **Database Backups**
   - Daily automated backups
   - Store backups off-site
   - Test restore procedures

2. **Application Backups**
   - Code is in Git repository
   - Configuration files backed up
   - Docker volumes backed up

3. **SSL Certificates**
   - Certificates are automatically renewed
   - Backup certificate volumes

## Support

For issues or questions:
1. Check the logs first
2. Review this documentation
3. Check Docker and nginx-proxy documentation
4. Contact your system administrator

## Architecture Overview

```
Internet
    ↓
nginx-proxy (Port 80/443)
    ↓
├── app.leython.com → Frontend (Vue.js)
├── api.leython.com → Backend (Laravel)
└── mail.leython.com → Postal (existing)

Backend Services:
├── Laravel API
├── Queue Worker
├── MySQL Database
└── Redis Cache

Frontend:
└── Vue.js SPA (Nginx)
```

This setup ensures your new email platform runs alongside your existing Postal server without conflicts, with automatic SSL and production-ready configuration.
