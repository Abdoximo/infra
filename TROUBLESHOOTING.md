# Eagle Email Platform - Troubleshooting Guide

## 🚨 **Common Issues and Solutions**

### **Issue 1: "unable to prepare context: path not found"**

**Error Message:**
```
unable to prepare context: path "/opt/eagle-platform/eagle" not found
```

**Causes:**
1. Running from wrong directory
2. Repositories not cloned correctly
3. Old docker-compose file with outdated paths

**Solutions:**

#### **Check Current Directory Structure**
```bash
# You should be in the infra directory
pwd
# Should show: /opt/eagle-platform/infra

# Check if all repositories are cloned
ls -la /opt/eagle-platform/
# Should show: backend/ frontend/ infra/
```

#### **Fix Directory Structure**
```bash
# If missing repositories, clone them
cd /opt/eagle-platform

# Clone missing repositories
git clone https://github.com/Abdoximo/eagle-backend.git backend
git clone https://github.com/Abdoximo/eagle-front.git frontend
git clone https://github.com/Abdoximo/infra.git infra

# Navigate to infra directory
cd infra
```

#### **Verify Docker Compose File**
```bash
# Check the build contexts in docker-compose.prod.yml
grep -A 2 "context:" docker-compose.prod.yml

# Should show:
# context: ../backend
# context: ../frontend
```

### **Issue 2: "version is obsolete" Warning**

**Error Message:**
```
WARN[0000] the attribute `version` is obsolete, it will be ignored
```

**Solution:**
The `version` field has been removed from the docker-compose.prod.yml file. This warning can be ignored or you can update to the latest Docker Compose.

### **Issue 3: Permission Denied**

**Error Message:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again, or run:
newgrp docker

# Verify docker access
docker ps
```

### **Issue 4: Port Already in Use**

**Error Message:**
```
bind: address already in use
```

**Solution:**
```bash
# Check what's using the ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Stop conflicting services
sudo systemctl stop apache2  # if Apache is running
sudo systemctl stop nginx    # if Nginx is running

# Or change ports in docker-compose.prod.yml
```

### **Issue 5: SSL Certificate Issues**

**Error Message:**
```
SSL certificate not found
```

**Solution:**
```bash
# Check DNS configuration
nslookup api.leython.com
nslookup app.leython.com

# Wait for certificates (can take 5-10 minutes)
docker-compose -f docker-compose.prod.yml logs letsencrypt

# Restart SSL service
docker-compose -f docker-compose.prod.yml restart letsencrypt
```

## 🔧 **Diagnostic Commands**

### **Check System Status**
```bash
# Check Docker status
docker --version
docker-compose --version
docker ps

# Check disk space
df -h

# Check memory usage
free -h

# Check network connectivity
ping google.com
```

### **Check Application Status**
```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f

# Check specific service logs
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs frontend
docker-compose -f docker-compose.prod.yml logs nginx-proxy
```

### **Check Directory Structure**
```bash
# Verify correct structure
tree /opt/eagle-platform/ -L 2

# Should show:
# /opt/eagle-platform/
# ├── backend/
# ├── frontend/
# └── infra/
```

## 🚀 **Complete Reset and Redeploy**

If you're having persistent issues, here's how to completely reset and redeploy:

```bash
# Stop all containers
docker-compose -f docker-compose.prod.yml down

# Remove all containers and volumes (WARNING: This will delete data)
docker-compose -f docker-compose.prod.yml down -v
docker system prune -a

# Remove application directory
sudo rm -rf /opt/eagle-platform

# Start fresh
sudo mkdir -p /opt/eagle-platform
sudo chown $USER:$USER /opt/eagle-platform
cd /opt/eagle-platform

# Clone repositories
git clone https://github.com/Abdoximo/eagle-backend.git backend
git clone https://github.com/Abdoximo/eagle-front.git frontend
git clone https://github.com/Abdoximo/infra.git infra

# Deploy
cd infra
cp production.env .env
# Edit .env with your values
./deploy.sh production
```

## 📋 **Pre-Deployment Checklist**

Before deploying, ensure:

- [ ] All three repositories are cloned in `/opt/eagle-platform/`
- [ ] You're running commands from `/opt/eagle-platform/infra/`
- [ ] Docker and Docker Compose are installed
- [ ] User has docker group permissions
- [ ] Ports 80 and 443 are available
- [ ] DNS records are configured
- [ ] `.env` file is configured with correct values

## 🆘 **Getting Help**

If you're still having issues:

1. **Check logs**: `docker-compose -f docker-compose.prod.yml logs -f`
2. **Verify structure**: `ls -la /opt/eagle-platform/`
3. **Check permissions**: `ls -la /opt/eagle-platform/infra/`
4. **Test Docker**: `docker run hello-world`

## 📞 **Support Information**

- **Repository**: [https://github.com/Abdoximo/infra](https://github.com/Abdoximo/infra)
- **Backend**: [https://github.com/Abdoximo/eagle-backend](https://github.com/Abdoximo/eagle-backend)
- **Frontend**: [https://github.com/Abdoximo/eagle-front](https://github.com/Abdoximo/eagle-front)
