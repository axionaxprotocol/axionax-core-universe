# 🚀 Quick Start Guide - axionax-deploy

## Overview

**axionax-deploy** เป็น deployment และ infrastructure repository สำหรับการ deploy axionax protocol nodes, monitoring, และ infrastructure management

**Repository:** https://github.com/axionaxprotocol/axionax-deploy

---

## 📋 Prerequisites

```bash
# Required
- Node.js 18+
- Docker & Docker Compose
- Ansible (for automated deployment)
- Git

# Cloud Providers (choose one)
- AWS CLI (for AWS deployment)
- gcloud CLI (for GCP deployment)
- Azure CLI (for Azure deployment)
- DigitalOcean CLI (for DO deployment)

# Recommended
- kubectl (for Kubernetes)
- Terraform (for infrastructure as code)
- Helm (for Kubernetes deployments)
```

---

## 🔧 Installation

### 1. Clone Repository

```bash
git clone https://github.com/axionaxprotocol/axionax-deploy.git
cd axionax-deploy
```

### 2. Install Dependencies

```bash
# Install npm dependencies
npm install

# Install Ansible (if not installed)
pip install ansible

# Install Terraform (if using)
# On macOS
brew install terraform

# On Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 3. Setup Configuration

```bash
# Copy example config
cp config/example.env .env

# Edit configuration
nano .env

# Required variables:
# NETWORK=testnet
# NODE_TYPE=validator
# REGION=us-east-1
# PROVIDER=aws
```

---

## 🏃 Quick Deployment

### Local Development Deployment

```bash
# Deploy local testnet
npm run deploy:local

# This will:
# 1. Build axionax-core
# 2. Start local node
# 3. Setup monitoring
# 4. Create test accounts

# Access local node
curl http://localhost:8545
```

### Docker Deployment

```bash
# Build Docker image
docker build -t axionax-node .

# Run single node
docker run -p 8545:8545 -p 30333:30333 axionax-node

# Run with Docker Compose (full stack)
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f axionax-node
```

### Cloud Deployment

```bash
# Deploy to testnet
npm run deploy:testnet

# Deploy to mainnet (requires approval)
npm run deploy:mainnet

# Deploy specific component
npm run deploy:validator
npm run deploy:rpc
npm run deploy:monitoring
```

---

## 🏗️ Project Structure

```
axionax-deploy/
├── ansible/                    # Ansible playbooks
│   ├── playbooks/              # Deployment playbooks
│   │   ├── deploy-node.yml     # Deploy node
│   │   ├── deploy-validator.yml # Deploy validator
│   │   └── setup-monitoring.yml # Setup monitoring
│   ├── roles/                  # Ansible roles
│   └── inventory/              # Server inventory
│
├── docker/                     # Docker configurations
│   ├── Dockerfile.node         # Node Dockerfile
│   ├── Dockerfile.validator    # Validator Dockerfile
│   └── docker-compose.yml      # Multi-container setup
│
├── kubernetes/                 # Kubernetes manifests
│   ├── deployments/            # Deployments
│   ├── services/               # Services
│   ├── configmaps/             # ConfigMaps
│   └── helm/                   # Helm charts
│
├── terraform/                  # Terraform configs
│   ├── aws/                    # AWS infrastructure
│   ├── gcp/                    # GCP infrastructure
│   └── modules/                # Reusable modules
│
├── scripts/                    # Deployment scripts
│   ├── deploy.sh               # Main deployment
│   ├── setup-node.sh           # Node setup
│   ├── backup.sh               # Backup script
│   └── restore.sh              # Restore script
│
├── monitoring/                 # Monitoring configs
│   ├── prometheus/             # Prometheus config
│   ├── grafana/                # Grafana dashboards
│   └── alertmanager/           # Alert rules
│
├── config/                     # Configuration files
│   ├── node.toml               # Node configuration
│   ├── validator.toml          # Validator configuration
│   └── network.toml            # Network configuration
│
└── docs/                       # Deployment documentation
```

---

## 🔨 Common Deployment Tasks

### Deploy Single Node

```bash
# Using script
./scripts/deploy.sh --type node --network testnet

# Using Ansible
ansible-playbook ansible/playbooks/deploy-node.yml \
  -e "network=testnet" \
  -e "node_type=full"

# Using Docker
docker run -d \
  --name axionax-node \
  -p 8545:8545 \
  -p 30333:30333 \
  -v $(pwd)/data:/data \
  axionax-node:latest
```

### Deploy Validator

```bash
# Generate validator keys
./scripts/generate-keys.sh

# Deploy validator node
./scripts/deploy.sh --type validator --network testnet

# Register validator
npm run validator:register

# Start validating
npm run validator:start
```

### Deploy RPC Node

```bash
# Deploy RPC node with load balancing
./scripts/deploy.sh --type rpc --count 3

# Setup nginx load balancer
ansible-playbook ansible/playbooks/setup-loadbalancer.yml

# Test RPC endpoints
curl http://rpc.axionax.org/health
```

---

## 🔍 Monitoring & Logging

### Setup Monitoring Stack

```bash
# Deploy Prometheus + Grafana
npm run deploy:monitoring

# Access Grafana
# http://localhost:3000
# Default: admin/admin

# Import dashboards
# monitoring/grafana/dashboards/

# Configure alerts
# monitoring/alertmanager/alerts.yml
```

### View Logs

```bash
# Docker logs
docker-compose logs -f axionax-node

# Kubernetes logs
kubectl logs -f axionax-node-0

# System logs
journalctl -u axionax-node -f

# Application logs
tail -f /var/log/axionax/node.log
```

### Metrics Endpoints

```bash
# Node metrics
curl http://localhost:9615/metrics

# Prometheus metrics
curl http://localhost:9090/api/v1/query?query=up

# Check node health
curl http://localhost:8545/health
```

---

## 🔧 Infrastructure as Code

### Terraform Deployment

```bash
cd terraform/aws

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=plan.out

# Apply infrastructure
terraform apply plan.out

# Destroy infrastructure
terraform destroy
```

### Terraform Modules

```hcl
# terraform/aws/main.tf
module "axionax_node" {
  source = "../modules/node"
  
  instance_type = "t3.large"
  network       = "testnet"
  region        = "us-east-1"
  node_count    = 3
}

module "monitoring" {
  source = "../modules/monitoring"
  
  enable_prometheus = true
  enable_grafana    = true
}
```

---

## ☸️ Kubernetes Deployment

### Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace axionax

# Deploy using manifests
kubectl apply -f kubernetes/deployments/

# Deploy using Helm
helm install axionax kubernetes/helm/axionax \
  --namespace axionax \
  --set network=testnet

# Check deployment
kubectl get pods -n axionax

# Get service URL
kubectl get svc -n axionax
```

### Scale Deployment

```bash
# Scale nodes
kubectl scale deployment axionax-node --replicas=5

# Autoscaling
kubectl autoscale deployment axionax-node \
  --min=3 --max=10 --cpu-percent=70
```

---

## 🔐 Security & Backup

### Setup SSL/TLS

```bash
# Generate SSL certificate
./scripts/setup-ssl.sh

# Setup Let's Encrypt
certbot certonly --standalone \
  -d rpc.axionax.org \
  -d ws.axionax.org

# Configure nginx with SSL
ansible-playbook ansible/playbooks/setup-ssl.yml
```

### Backup & Restore

```bash
# Backup node data
./scripts/backup.sh

# Backup to S3
aws s3 sync /data/axionax s3://axionax-backups/

# Restore from backup
./scripts/restore.sh --backup-id 2024-01-01

# Automated backups (cron)
0 2 * * * /opt/axionax-deploy/scripts/backup.sh
```

---

## 🔌 Integration with Other Repos

### With axionax-core

```bash
# Clone and build axionax-core
cd ..
git clone https://github.com/axionaxprotocol/axionax-core.git
cd axionax-core
cargo build --release

# Copy binary to deploy
cp target/release/axionax-node ../axionax-deploy/binaries/

# Deploy with custom binary
./scripts/deploy.sh --binary binaries/axionax-node
```

### With axionax-sdk-ts

```bash
# Deploy includes RPC endpoints for SDK
# SDK connects to deployed nodes:

# In axionax-sdk-ts:
const client = new AxionaxClient('https://rpc.axionax.org')
```

### With axionax-web

```bash
# Deploy web dashboard
cd ../axionax-web
npm run build

# Copy to deployment
cp -r out ../axionax-deploy/static/dashboard

# Serve with nginx
ansible-playbook ansible/playbooks/deploy-dashboard.yml
```

---

## 📊 Performance Tuning

### Node Optimization

```toml
# config/node.toml - Optimized settings
[performance]
max_connections = 100
cache_size = "4GB"
threads = 8

[network]
max_peers = 50
discovery_interval = 10
```

### Database Optimization

```bash
# Optimize RocksDB
./scripts/optimize-db.sh

# Prune old data
./scripts/prune-data.sh --keep-last 1000
```

---

## 🚨 Troubleshooting

### Node Not Starting

```bash
# Check logs
journalctl -u axionax-node -n 100

# Verify configuration
./scripts/validate-config.sh

# Test connectivity
telnet localhost 30333

# Reset node data
rm -rf /data/axionax/db
./scripts/deploy.sh --clean
```

### Network Issues

```bash
# Check firewall
sudo ufw status

# Open required ports
sudo ufw allow 8545/tcp  # RPC
sudo ufw allow 30333/tcp # P2P

# Test peer connections
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system_peers","params":[],"id":1}'
```

### Performance Issues

```bash
# Check resource usage
htop
iostat -x 1
netstat -an | grep ESTABLISHED | wc -l

# Optimize system
./scripts/tune-system.sh

# Increase limits
ulimit -n 65535
```

---

## 📝 Configuration Examples

### Node Configuration

```toml
# config/node.toml
[network]
listen_addr = "0.0.0.0:30333"
external_addr = "YOUR_PUBLIC_IP:30333"
bootnodes = [
  "/dns4/boot1.axionax.org/tcp/30333/p2p/...",
  "/dns4/boot2.axionax.org/tcp/30333/p2p/..."
]

[rpc]
http_addr = "0.0.0.0:8545"
ws_addr = "0.0.0.0:8546"
cors = ["*"]

[validator]
enabled = true
key_path = "/keys/validator.key"
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  axionax-node:
    image: axionax/node:latest
    ports:
      - "8545:8545"
      - "30333:30333"
    volumes:
      - ./data:/data
      - ./config:/config
    environment:
      - NETWORK=testnet
      - LOG_LEVEL=info
    restart: unless-stopped

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
```

---

## 📚 Additional Resources

- **Deployment Guide:** [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- **Security Best Practices:** [docs/SECURITY.md](docs/SECURITY.md)
- **Monitoring Guide:** [docs/MONITORING.md](docs/MONITORING.md)
- **Troubleshooting:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 🤝 Getting Help

- **Issues:** Report issues on [GitHub Issues](https://github.com/axionaxprotocol/axionax-deploy/issues)
- **Documentation:** Check [axionax-docs](https://github.com/axionaxprotocol/axionax-docs)
- **Core Node:** See [axionax-core](https://github.com/axionaxprotocol/axionax-core)

---

## 📄 License

MIT - See [LICENSE](LICENSE) file for details

---

<p align="center">
  <sub>Built with ❤️ by the axionax protocol Team</sub>
</p>
