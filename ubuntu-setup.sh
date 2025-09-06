#!/bin/bash

# Eagle Email Platform - Ubuntu Server Setup Script
# This script automates the complete setup process

set -e

echo "🚀 Starting Eagle Email Platform setup on Ubuntu..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    print_error "This script requires sudo privileges. Please run with a user that has sudo access."
    exit 1
fi

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing essential packages..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

print_status "Setting timezone to UTC..."
sudo timedatectl set-timezone UTC

print_status "Installing Docker Engine..."
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

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

print_success "Docker Engine installed successfully"

print_status "Installing Docker Compose (standalone)..."
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

print_success "Docker Compose installed successfully"

print_status "Adding user to docker group..."
sudo usermod -aG docker $USER

print_status "Configuring firewall..."
# Enable UFW
sudo ufw --force enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

print_success "Firewall configured"

print_status "Creating application directory..."
sudo mkdir -p /opt/eagle-platform
sudo chown $USER:$USER /opt/eagle-platform

print_status "Setting up application..."
cd /opt/eagle-platform

print_status "Cloning repositories..."

# Clone backend repository
print_status "Cloning backend repository..."
git clone https://github.com/Abdoximo/eagle-backend.git backend

# Clone frontend repository
print_status "Cloning frontend repository..."
git clone https://github.com/Abdoximo/eagle-front.git frontend

# Clone infrastructure repository
print_status "Cloning infrastructure repository..."
git clone https://github.com/Abdoximo/infra.git infra

if [ ! -d "infra" ]; then
    print_error "Infrastructure repository clone failed."
    exit 1
fi

cd infra

print_status "Configuring environment..."
cp production.env .env

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
DB_ROOT_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
APP_KEY=$(openssl rand -base64 32)

print_status "Updating .env file with generated values..."

# Update critical environment variables
sed -i "s/your_secure_database_password/${DB_PASSWORD}/g" .env
sed -i "s/your_secure_root_password/${DB_ROOT_PASSWORD}/g" .env
sed -i "s/your_secure_redis_password/${REDIS_PASSWORD}/g" .env
sed -i "s/APP_KEY=/APP_KEY=${APP_KEY}/g" .env

print_success "Environment configured"

print_status "Making deployment script executable..."
chmod +x deploy.sh

print_status "Starting application deployment..."
./deploy.sh production

print_success "Eagle Email Platform setup completed!"

echo ""
echo "🎉 Setup Summary:"
echo "=================="
echo "✅ Docker Engine installed"
echo "✅ Docker Compose installed"
echo "✅ Firewall configured"
echo "✅ Application deployed"
echo "✅ Laravel initialized"
echo ""
echo "🌐 Your application will be available at:"
echo "   Frontend: https://app.leython.com"
echo "   Backend API: https://api.leython.com"
echo ""
echo "📋 Next steps:"
echo "1. Configure DNS records to point to this server:"
echo "   - api.leython.com -> $(curl -s ifconfig.me)"
echo "   - app.leython.com -> $(curl -s ifconfig.me)"
echo "2. Update .env file with your actual Postal credentials"
echo "3. Wait for SSL certificates to be generated (first access may take a few minutes)"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: docker-compose -f docker-compose.prod.yml ps"
echo "   View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   Restart: docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "📚 For detailed information, see: UBUNTU_DEPLOYMENT_GUIDE.md"
echo ""
print_warning "Please logout and login again to apply Docker group changes, or run: newgrp docker"
