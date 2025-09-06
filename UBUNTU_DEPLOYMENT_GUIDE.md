# Eagle Email Platform - Ubuntu Server Deployment Guide

## 📋 **System Analysis & Requirements**

### **Application Stack Analysis**
- **Backend**: Laravel 12.0 with PHP 8.2+
- **Frontend**: Vue.js 3.4 with TypeScript and Vite
- **Database**: MySQL 8.0
- **Cache**: Redis 7
- **Queue**: Laravel Queues with Redis
- **Proxy**: nginx-proxy with Let's Encrypt SSL
- **Containerization**: Docker + Docker Compose

### **System Requirements**
- **OS**: Ubuntu 20.04 LTS or 22.04 LTS (recommended)
- **CPU**: 2+ cores (4+ recommended for production)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 50GB+ SSD (100GB+ recommended)
- **Network**: Public IP with ports 80/443 open
- **Domain**: leython.com with subdomains configured

### **Dependencies**
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- curl/wget
- Basic firewall (UFW)

---

## 🚀 **Complete Ubuntu Server Setup**

### **Step 1: Initial Server Setup**

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Set timezone
sudo timedatectl set-timezone UTC

# Create application user (optional but recommended)
sudo adduser --gecos "" --disabled-password eagle
sudo usermod -aG sudo eagle
sudo usermod -aG docker eagle
```

### **Step 2: Install Docker Engine**

```bash
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
sudo docker --version
sudo docker compose version
```

### **Step 3: Install Docker Compose (Standalone)**

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

### **Step 4: Configure Firewall**

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

### **Step 5: Clone Repository**

```bash
# Create application directory
sudo mkdir -p /opt/eagle-platform
sudo chown eagle:eagle /opt/eagle-platform

# Switch to eagle user
sudo su - eagle

# Clone repository (replace with your actual repo URL)
git clone https://github.com/yourusername/eagle-email-platform.git /opt/eagle-platform

# Navigate to project
cd /opt/eagle-platform/infra
```

### **Step 6: Configure Environment**

```bash
# Copy environment template
cp production.env .env

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
DB_ROOT_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
APP_KEY=$(openssl rand -base64 32)

# Update .env file with generated values
cat > .env << EOF
# Application Configuration
APP_NAME="Eagle Email Platform"
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=https://api.leython.com

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=database
DB_PORT=3306
DB_DATABASE=eagle_production
DB_USERNAME=eagle_user
DB_PASSWORD=${DB_PASSWORD}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}

# Redis Configuration
REDIS_HOST=redis
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT=6379
REDIS_DB=0

# Mail Configuration (Postal)
MAIL_MAILER=smtp
MAIL_HOST=postal
MAIL_PORT=25
MAIL_USERNAME=your_postal_username
MAIL_PASSWORD=your_postal_password
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=noreply@leython.com
MAIL_FROM_NAME="Eagle Email Platform"

# Queue Configuration
QUEUE_CONNECTION=redis

# Cache Configuration
CACHE_DRIVER=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

# File Storage
FILESYSTEM_DISK=local

# Logging
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

# Broadcasting
BROADCAST_DRIVER=log

# Stripe Configuration (if using Stripe)
STRIPE_KEY=your_stripe_publishable_key
STRIPE_SECRET=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

# Postal API Configuration
POSTAL_API_URL=http://postal:5000
POSTAL_API_KEY=your_postal_api_key
POSTAL_SERVER_ID=your_postal_server_id

# Security
SANCTUM_STATEFUL_DOMAINS=app.leython.com,api.leython.com
SESSION_DOMAIN=.leython.com

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://app.leython.com
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60

# File Upload Limits
MAX_FILE_SIZE=10485760
MAX_FILES_PER_UPLOAD=10

# Email Limits
MAX_EMAILS_PER_CAMPAIGN=10000
MAX_DAILY_EMAILS=100000

# Monitoring (optional)
SENTRY_LARAVEL_DSN=
SENTRY_TRACES_SAMPLE_RATE=0.1

# Backup Configuration
BACKUP_DISK=local
BACKUP_RETENTION_DAYS=30
EOF

# Make deployment script executable
chmod +x deploy.sh
```

### **Step 7: Configure DNS**

Before deploying, configure your DNS records:

```
A    api.leython.com    -> YOUR_SERVER_IP
A    app.leython.com    -> YOUR_SERVER_IP
A    leython.com        -> YOUR_SERVER_IP
```

### **Step 8: Deploy Application**

```bash
# Deploy using the automated script
./deploy.sh production

# Or deploy manually
docker-compose -f docker-compose.prod.yml up -d --build
```

### **Step 9: Initialize Laravel Application**

```bash
# Generate application key (if not set)
docker-compose -f docker-compose.prod.yml exec backend php artisan key:generate --force

# Run database migrations
docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force

# Cache configuration for production
docker-compose -f docker-compose.prod.yml exec backend php artisan config:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan route:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan view:cache

# Create storage link
docker-compose -f docker-compose.prod.yml exec backend php artisan storage:link

# Set proper permissions
docker-compose -f docker-compose.prod.yml exec backend chown -R www-data:www-data /var/www/html/storage
docker-compose -f docker-compose.prod.yml exec backend chmod -R 755 /var/www/html/storage

# Seed initial data (optional)
docker-compose -f docker-compose.prod.yml exec backend php artisan db:seed
```

### **Step 10: Verify Deployment**

```bash
# Check all services are running
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f

# Test health endpoints
curl -f http://localhost/health  # Frontend
curl -f http://localhost/api/health  # Backend (if you have one)

# Check SSL certificates
curl -I https://api.leython.com
curl -I https://app.leython.com
```

---

## 🔧 **Post-Deployment Configuration**

### **Configure System Services**

```bash
# Create systemd service for auto-start
sudo tee /etc/systemd/system/eagle-platform.service > /dev/null << EOF
[Unit]
Description=Eagle Email Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/eagle-platform/infra
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0
User=eagle
Group=eagle

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable eagle-platform.service
sudo systemctl start eagle-platform.service
```

### **Setup Log Rotation**

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/eagle-platform > /dev/null << EOF
/opt/eagle-platform/infra/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 eagle eagle
    postrotate
        /usr/local/bin/docker-compose -f /opt/eagle-platform/infra/docker-compose.prod.yml restart backend worker
    endscript
}
EOF
```

### **Setup Database Backup**

```bash
# Create backup script
sudo tee /opt/eagle-platform/backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/eagle-platform/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="eagle_backup_${DATE}.sql"

mkdir -p $BACKUP_DIR

# Load environment variables
cd /opt/eagle-platform/infra
export $(cat .env | grep -v '^#' | xargs)

# Create database backup
docker-compose -f docker-compose.prod.yml exec -T database mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_DATABASE} > ${BACKUP_DIR}/${BACKUP_FILE}

# Compress backup
gzip ${BACKUP_DIR}/${BACKUP_FILE}

# Remove backups older than 30 days
find ${BACKUP_DIR} -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
EOF

# Make backup script executable
sudo chmod +x /opt/eagle-platform/backup.sh

# Add to crontab
(crontab -u eagle -l 2>/dev/null; echo "0 2 * * * /opt/eagle-platform/backup.sh") | crontab -u eagle -
```

---

## 📊 **Monitoring & Maintenance**

### **Health Monitoring**

```bash
# Create health check script
sudo tee /opt/eagle-platform/health-check.sh > /dev/null << 'EOF'
#!/bin/bash
cd /opt/eagle-platform/infra

# Check if all containers are running
if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "ERROR: Some containers are not running"
    docker-compose -f docker-compose.prod.yml ps
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /opt/eagle-platform | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ $MEMORY_USAGE -gt 90 ]; then
    echo "WARNING: Memory usage is ${MEMORY_USAGE}%"
fi

echo "Health check passed"
EOF

sudo chmod +x /opt/eagle-platform/health-check.sh

# Add to crontab (every 5 minutes)
(crontab -u eagle -l 2>/dev/null; echo "*/5 * * * * /opt/eagle-platform/health-check.sh") | crontab -u eagle -
```

### **Update Application**

```bash
# Create update script
sudo tee /opt/eagle-platform/update.sh > /dev/null << 'EOF'
#!/bin/bash
cd /opt/eagle-platform

# Pull latest changes
git pull origin main

# Navigate to infra directory
cd infra

# Rebuild and restart services
docker-compose -f docker-compose.prod.yml up -d --build

# Run migrations if needed
docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force

# Clear caches
docker-compose -f docker-compose.prod.yml exec backend php artisan config:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan route:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan view:cache

echo "Update completed"
EOF

sudo chmod +x /opt/eagle-platform/update.sh
```

---

## 🚨 **Troubleshooting**

### **Common Issues & Solutions**

1. **SSL Certificate Issues**
   ```bash
   # Check nginx-proxy logs
   docker-compose -f docker-compose.prod.yml logs nginx-proxy
   
   # Check Let's Encrypt logs
   docker-compose -f docker-compose.prod.yml logs letsencrypt
   
   # Restart SSL service
   docker-compose -f docker-compose.prod.yml restart letsencrypt
   ```

2. **Database Connection Issues**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.prod.yml logs database
   
   # Test database connection
   docker-compose -f docker-compose.prod.yml exec backend php artisan tinker
   # Then run: DB::connection()->getPdo();
   ```

3. **Frontend Not Loading**
   ```bash
   # Check frontend logs
   docker-compose -f docker-compose.prod.yml logs frontend
   
   # Check nginx-proxy configuration
   docker-compose -f docker-compose.prod.yml exec nginx-proxy cat /etc/nginx/conf.d/default.conf
   ```

4. **Memory Issues**
   ```bash
   # Check memory usage
   docker stats
   
   # Clean up unused resources
   docker system prune -a
   
   # Restart services
   docker-compose -f docker-compose.prod.yml restart
   ```

### **Useful Commands**

```bash
# View all logs
docker-compose -f docker-compose.prod.yml logs -f

# Access backend container
docker-compose -f docker-compose.prod.yml exec backend bash

# Access database
docker-compose -f docker-compose.prod.yml exec database mysql -u root -p

# Check service status
docker-compose -f docker-compose.prod.yml ps

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend

# View resource usage
docker stats

# Clean up Docker
docker system prune -a
```

---

## 🔒 **Security Hardening**

### **Server Security**

```bash
# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### **Application Security**

```bash
# Set proper file permissions
sudo chown -R eagle:eagle /opt/eagle-platform
sudo chmod -R 755 /opt/eagle-platform
sudo chmod 600 /opt/eagle-platform/infra/.env

# Enable Docker content trust
export DOCKER_CONTENT_TRUST=1
```

---

## 📈 **Performance Optimization**

### **System Optimization**

```bash
# Optimize kernel parameters
sudo tee -a /etc/sysctl.conf > /dev/null << EOF
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# File system optimizations
fs.file-max = 2097152
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

# Apply changes
sudo sysctl -p
```

### **Docker Optimization**

```bash
# Configure Docker daemon
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Restart Docker
sudo systemctl restart docker
```

---

## 🎯 **Final Checklist**

- [ ] Ubuntu server prepared and updated
- [ ] Docker and Docker Compose installed
- [ ] Firewall configured (ports 80, 443, 22)
- [ ] Repository cloned to `/opt/eagle-platform`
- [ ] Environment variables configured
- [ ] DNS records pointing to server
- [ ] Application deployed successfully
- [ ] Laravel initialized (migrations, caching)
- [ ] SSL certificates generated
- [ ] Health monitoring configured
- [ ] Backup system configured
- [ ] Security hardening applied
- [ ] Performance optimization applied

---

## 🌐 **Access Your Application**

- **Frontend**: `https://app.leython.com`
- **Backend API**: `https://api.leython.com`
- **Existing Postal**: `https://mail.leython.com` (unchanged)

Your Eagle Email Platform is now running alongside your existing Postal server with automatic SSL, production-ready configuration, and comprehensive monitoring!
