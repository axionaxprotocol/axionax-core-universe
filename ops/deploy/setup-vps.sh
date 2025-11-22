#!/bin/bash

# VPS Deployment Setup Script
# This script sets up the axionax protocol infrastructure on a VPS

set -e

echo "=== axionax VPS Deployment Setup ==="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}Updating system...${NC}"
apt-get update
apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo -e "${GREEN}Docker already installed${NC}"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}Docker Compose already installed${NC}"
fi

# Create deployment directory
DEPLOY_DIR="/opt/axionax"
echo -e "${YELLOW}Creating deployment directory: ${DEPLOY_DIR}${NC}"
mkdir -p ${DEPLOY_DIR}
cd ${DEPLOY_DIR}

# Check for .env file
if [ ! -f .env ]; then
    echo -e "${RED}.env file not found!${NC}"
    echo -e "${YELLOW}Please create .env file with required variables${NC}"
    echo "Copy from .env.example and fill in your values"
    exit 1
fi

# Load environment variables
source .env

# Setup SSL certificates with Certbot
echo -e "${YELLOW}Setting up SSL certificates...${NC}"
mkdir -p ./certbot/conf ./certbot/www

# Initial certificate request (HTTP challenge)
docker-compose -f docker-compose.vps.yml up -d nginx certbot

# Request certificates for each subdomain
DOMAINS=("rpc" "explorer" "faucet")
for domain in "${DOMAINS[@]}"; do
    FULL_DOMAIN="${domain}.${DOMAIN}"
    echo -e "${YELLOW}Requesting certificate for ${FULL_DOMAIN}${NC}"
    
    docker-compose -f docker-compose.vps.yml run --rm certbot \
        certonly --webroot \
        -w /var/www/certbot \
        --email admin@${DOMAIN} \
        --agree-tos \
        --no-eff-email \
        -d ${FULL_DOMAIN}
done

# Start all services
echo -e "${YELLOW}Starting all services...${NC}"
docker-compose -f docker-compose.vps.yml up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 30

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"
services=("rpc-node:8545/health" "explorer-backend:3001/api/health" "faucet:3002/health")
for service in "${services[@]}"; do
    IFS=':' read -r name endpoint <<< "$service"
    if docker exec axionax-${name} curl -f http://localhost:${endpoint} &>/dev/null; then
        echo -e "${GREEN}✓ ${name} is healthy${NC}"
    else
        echo -e "${RED}✗ ${name} is not responding${NC}"
    fi
done

# Setup firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 30303/tcp  # P2P
    ufw allow 30303/udp
    ufw reload
    echo -e "${GREEN}Firewall configured${NC}"
fi

# Print service URLs
echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Services are available at:"
echo -e "${GREEN}RPC Node:${NC}      https://rpc.${DOMAIN}"
echo -e "${GREEN}Explorer:${NC}      https://explorer.${DOMAIN}"
echo -e "${GREEN}Faucet:${NC}        https://faucet.${DOMAIN}"
echo -e "${GREEN}Grafana:${NC}       http://${VPS_IP}:3000 (admin/${GRAFANA_PASSWORD})"
echo -e "${GREEN}Prometheus:${NC}    http://${VPS_IP}:9090"
echo ""
echo "To view logs:"
echo "  docker-compose -f docker-compose.vps.yml logs -f [service-name]"
echo ""
echo "To restart services:"
echo "  docker-compose -f docker-compose.vps.yml restart"
echo ""
echo -e "${YELLOW}Note: Make sure DNS records are configured correctly${NC}"
echo "A records for rpc/explorer/faucet should point to: ${VPS_IP}"
