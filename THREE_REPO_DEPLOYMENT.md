# Eagle Email Platform - Three Repository Deployment Guide

## 📋 **Repository Structure**

This deployment uses three separate repositories as referenced from [GitHub](https://github.com/Abdoximo):

- **Backend**: [https://github.com/Abdoximo/eagle-backend.git](https://github.com/Abdoximo/eagle-backend.git) - Laravel API
- **Frontend**: [https://github.com/Abdoximo/eagle-front.git](https://github.com/Abdoximo/eagle-front.git) - Vue.js SPA  
- **Infrastructure**: [https://github.com/Abdoximo/infra.git](https://github.com/Abdoximo/infra.git) - Docker configuration

## 🚀 **Quick Deployment (Ubuntu)**

### **One-Command Setup**
```bash
# Download and run the automated setup script
curl -fsSL https://raw.githubusercontent.com/Abdoximo/infra/main/ubuntu-setup.sh | bash
```

### **Manual Setup**

#### **1. Connect to Ubuntu Server**
```bash
ssh user@your-server-ip
```

#### **2. Install Prerequisites**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install other dependencies
sudo apt install -y git curl wget unzip
```

#### **3. Clone All Repositories**
```bash
# Create application directory
sudo mkdir -p /opt/eagle-platform
sudo chown $USER:$USER /opt/eagle-platform
cd /opt/eagle-platform

# Clone all three repositories
git clone https://github.com/Abdoximo/eagle-backend.git backend
git clone https://github.com/Abdoximo/eagle-front.git frontend
git clone https://github.com/Abdoximo/infra.git infra

# Navigate to infrastructure directory
cd infra
```

#### **4. Configure Environment**
```bash
# Copy environment template
cp production.env .env

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
DB_ROOT_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
APP_KEY=$(openssl rand -base64 32)

# Update .env file
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

# Security
SANCTUM_STATEFUL_DOMAINS=app.leython.com,api.leython.com
SESSION_DOMAIN=.leython.com

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://app.leython.com
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With
EOF

# Edit with your actual values
nano .env
```

#### **5. Configure DNS**
Point these domains to your server IP:
```
A    api.leython.com    -> YOUR_SERVER_IP
A    app.leython.com    -> YOUR_SERVER_IP
A    leython.com        -> YOUR_SERVER_IP
```

#### **6. Deploy Application**
```bash
# Make deployment script executable
chmod +x deploy.sh

# Deploy using automated script
./deploy.sh production

# Or deploy manually
docker-compose -f docker-compose.prod.yml up -d --build
```

#### **7. Initialize Laravel**
```bash
# Generate application key
docker-compose -f docker-compose.prod.yml exec backend php artisan key:generate --force

# Run database migrations
docker-compose -f docker-compose.prod.yml exec backend php artisan migrate --force

# Cache configuration
docker-compose -f docker-compose.prod.yml exec backend php artisan config:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan route:cache
docker-compose -f docker-compose.prod.yml exec backend php artisan view:cache

# Create storage link
docker-compose -f docker-compose.prod.yml exec backend php artisan storage:link

# Set permissions
docker-compose -f docker-compose.prod.yml exec backend chown -R www-data:www-data /var/www/html/storage
docker-compose -f docker-compose.prod.yml exec backend chmod -R 755 /var/www/html/storage
```

#### **8. Verify Deployment**
```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Test endpoints
curl -I https://api.leython.com
curl -I https://app.leython.com
```

## 📁 **Directory Structure After Deployment**

```
/opt/eagle-platform/
├── backend/                 # Laravel API (from eagle-backend repo)
│   ├── app/
│   ├── config/
│   ├── database/
│   ├── Dockerfile
│   └── ...
├── frontend/               # Vue.js SPA (from eagle-front repo)
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── ...
└── infra/                  # Infrastructure config (from infra repo)
    ├── docker-compose.prod.yml
    ├── production.env
    ├── ubuntu-setup.sh
    ├── deploy.sh
    └── ...
```

## 🔧 **Docker Compose Configuration**

The `docker-compose.prod.yml` file is configured to build from the relative paths:

```yaml
services:
  backend:
    build:
      context: ../backend      # Points to eagle-backend repo
      dockerfile: Dockerfile

  frontend:
    build:
      context: ../frontend     # Points to eagle-front repo
      dockerfile: Dockerfile

  worker:
    build:
      context: ../backend      # Same as backend (Laravel queue worker)
      dockerfile: Dockerfile
```

## 🌐 **Access Your Application**

After successful deployment:

- **Frontend**: `https://app.leython.com` (Vue.js SPA)
- **Backend API**: `https://api.leython.com` (Laravel API)
- **Existing Postal**: `https://mail.leython.com` (unchanged)

## 🔄 **Updating Applications**

### **Update All Repositories**
```bash
cd /opt/eagle-platform

# Update backend
cd backend && git pull origin main && cd ..

# Update frontend  
cd frontend && git pull origin main && cd ..

# Update infrastructure
cd infra && git pull origin main && cd ..

# Rebuild and restart
cd infra
docker-compose -f docker-compose.prod.yml up -d --build
```

### **Update Individual Services**
```bash
cd /opt/eagle-platform/infra

# Update only backend
cd ../backend && git pull origin main && cd ../infra
docker-compose -f docker-compose.prod.yml up -d --build backend worker

# Update only frontend
cd ../frontend && git pull origin main && cd ../infra
docker-compose -f docker-compose.prod.yml up -d --build frontend
```

## 🚨 **Troubleshooting**

### **Common Issues**

| Issue | Solution |
|-------|----------|
| Build context not found | Ensure all three repos are cloned in `/opt/eagle-platform/` |
| SSL not working | Check DNS, wait 5-10 minutes for certificates |
| Database connection error | Check database logs: `docker-compose logs database` |
| Frontend not loading | Check nginx-proxy logs: `docker-compose logs nginx-proxy` |

### **Useful Commands**

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Access containers
docker-compose -f docker-compose.prod.yml exec backend bash
docker-compose -f docker-compose.prod.yml exec frontend sh

# Check resource usage
docker stats
```

## 📊 **System Requirements**

- **OS**: Ubuntu 20.04+ or 22.04+
- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 50GB+ SSD
- **Network**: Public IP with ports 80/443 open

## 🔒 **Security Features**

- Automatic SSL certificates with Let's Encrypt
- Security headers configured
- Rate limiting enabled
- Non-root container users
- Firewall configuration
- Secure password generation

## 📚 **Additional Documentation**

- `UBUNTU_DEPLOYMENT_GUIDE.md` - Complete Ubuntu setup guide
- `DEPLOYMENT.md` - General deployment guide
- `QUICK_START.md` - Quick reference guide
- `README.md` - Infrastructure overview

This three-repository setup provides better separation of concerns and easier maintenance for your Eagle Email Platform!
