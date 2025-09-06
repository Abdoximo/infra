# Eagle Email Platform - Quick Start Guide

## 🚀 **One-Command Setup**

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/eagle-email-platform/main/infra/ubuntu-setup.sh | bash -s https://github.com/yourusername/eagle-email-platform.git
```

## 📋 **Manual Setup (Step by Step)**

### **1. Connect to Server**
```bash
ssh user@your-server-ip
```

### **2. Run Setup Script**
```bash
# Download setup script
wget https://raw.githubusercontent.com/yourusername/eagle-email-platform/main/infra/ubuntu-setup.sh
chmod +x ubuntu-setup.sh

# Run setup (replace with your repo URL)
./ubuntu-setup.sh https://github.com/yourusername/eagle-email-platform.git
```

### **3. Configure DNS**
Point these domains to your server IP:
```
A    api.leython.com    -> YOUR_SERVER_IP
A    app.leython.com    -> YOUR_SERVER_IP
A    leython.com        -> YOUR_SERVER_IP
```

### **4. Update Environment**
```bash
cd /opt/eagle-platform/infra
nano .env
# Update Postal credentials and other settings
```

### **5. Restart Application**
```bash
docker-compose -f docker-compose.prod.yml restart
```

## ✅ **Verify Deployment**

```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Test endpoints
curl -I https://api.leython.com
curl -I https://app.leython.com
```

## 🔧 **Common Commands**

```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Update application
cd /opt/eagle-platform && git pull && cd infra && docker-compose -f docker-compose.prod.yml up -d --build

# Access backend
docker-compose -f docker-compose.prod.yml exec backend bash

# Check health
./health-check.sh
```

## 🚨 **Troubleshooting**

| Issue | Solution |
|-------|----------|
| SSL not working | Check DNS, wait 5-10 minutes for certificates |
| Database error | Check database logs: `docker-compose logs database` |
| Frontend not loading | Check nginx-proxy logs: `docker-compose logs nginx-proxy` |
| Out of memory | Restart services: `docker-compose restart` |

## 📊 **System Requirements**

- **OS**: Ubuntu 20.04+ or 22.04+
- **CPU**: 2+ cores
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 50GB+ SSD
- **Network**: Public IP with ports 80/443 open

## 🌐 **Access URLs**

- **Frontend**: `https://app.leython.com`
- **Backend API**: `https://api.leython.com`
- **Existing Postal**: `https://mail.leython.com` (unchanged)

## 📚 **Full Documentation**

For complete setup instructions, see:
- `UBUNTU_DEPLOYMENT_GUIDE.md` - Complete Ubuntu setup guide
- `DEPLOYMENT.md` - General deployment guide
- `README.md` - Infrastructure overview
