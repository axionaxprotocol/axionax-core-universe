# axionax Protocol - VPS Deployment Scripts

Complete set of automated deployment and management scripts for axionax protocol infrastructure.

## 📁 Scripts Overview

### 🚀 Deployment Scripts

#### 1. `deploy-all-services.sh` - Complete Service Deployment
Automated deployment of all axionax services with health checks and verification.

**Usage:**
```bash
# Check system requirements only
sudo ./scripts/deploy-all-services.sh --check-only

# Deploy essential services only (RPC + Faucet + Infrastructure)
sudo ./scripts/deploy-all-services.sh --minimal

# Deploy all services (recommended for 8GB+ RAM)
sudo ./scripts/deploy-all-services.sh --full
```

**Features:**
- ✅ Pre-flight system resource checks
- ✅ Automatic Docker installation
- ✅ Environment validation
- ✅ Phased deployment (Infrastructure → Core → Applications → Monitoring)
- ✅ Health checks for each service
- ✅ Post-deployment verification
- ✅ Detailed logging

**Deployment Phases:**
1. **Phase 1: Infrastructure** - PostgreSQL, Redis
2. **Phase 2: Core Services** - RPC Node
3. **Phase 3: Applications** - Block Explorer, Faucet
4. **Phase 4: Monitoring** - Prometheus, Grafana
5. **Phase 5: Proxy** - Nginx, SSL

---

### 📊 Status & Monitoring Scripts

#### 2. `check-vps-status.sh` - Comprehensive Status Check
Real-time health monitoring of all services and system resources.

**Usage:**
```bash
# Quick status check
./scripts/check-vps-status.sh

# Detailed status with logs and metrics
./scripts/check-vps-status.sh --detailed
```

**What it checks:**
- ✅ System resources (RAM, CPU, Disk)
- ✅ Docker status
- ✅ Service health (all endpoints)
- ✅ Container details
- ✅ Network connectivity
- ✅ Database status
- ✅ Performance metrics
- ✅ Recent errors

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  QUICK SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Services Status: 9/9 running
✓ All services are running

Resource Usage:
  RAM:  45%
  Disk: 32%

✓ Overall Status: HEALTHY ✨
```

---

### 🔧 Service Management Scripts

#### 3. `manage-services.sh` - Individual Service Control
Simple interface to manage specific services.

**Usage:**
```bash
# Start a service
./scripts/manage-services.sh start rpc-node

# Stop a service
./scripts/manage-services.sh stop faucet

# Restart a service
./scripts/manage-services.sh restart nginx

# View logs (follow mode)
./scripts/manage-services.sh logs explorer-backend

# Check service status
./scripts/manage-services.sh status grafana

# Rebuild and restart
./scripts/manage-services.sh rebuild rpc-node

# Manage all services
./scripts/manage-services.sh restart all
```

**Available Services:**
- `nginx` - Web server / reverse proxy
- `certbot` - SSL certificate management
- `rpc-node` - axionax RPC endpoint
- `explorer-backend` - Block explorer API
- `faucet` - Testnet token distribution
- `postgres` - Database
- `redis` - Cache
- `prometheus` - Metrics collection
- `grafana` - Dashboard
- `all` - All services

---

## 📋 Quick Start Guide

### Initial Deployment

1. **Check system requirements:**
```bash
cd /opt/axionax-deploy
sudo ./scripts/deploy-all-services.sh --check-only
```

2. **Configure environment:**
```bash
# Copy and edit .env file
cp .env.example .env
nano .env

# Required variables:
# - DB_PASSWORD
# - REDIS_PASSWORD
# - FAUCET_PRIVATE_KEY
# - GRAFANA_PASSWORD
# - VPS_IP
# - DOMAIN (optional)
```

3. **Deploy services:**
```bash
# For 8GB+ RAM VPS (recommended)
sudo ./scripts/deploy-all-services.sh --full

# For 4-8GB RAM VPS
sudo ./scripts/deploy-all-services.sh --minimal
```

4. **Verify deployment:**
```bash
./scripts/check-vps-status.sh --detailed
```

---

## 🔄 Common Operations

### Daily Operations

**Check status:**
```bash
./scripts/check-vps-status.sh
```

**View service logs:**
```bash
./scripts/manage-services.sh logs rpc-node
./scripts/manage-services.sh logs faucet
```

**Restart a problematic service:**
```bash
./scripts/manage-services.sh restart explorer-backend
```

### Maintenance

**Update all services:**
```bash
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml pull
./scripts/manage-services.sh restart all
```

**Backup database:**
```bash
docker exec axionax-postgres pg_dump -U explorer explorer > backup-$(date +%Y%m%d).sql
```

**Clean up Docker resources:**
```bash
docker system prune -a --volumes
```

### Troubleshooting

**Service won't start:**
```bash
# Check logs
./scripts/manage-services.sh logs [service-name]

# Check status
./scripts/manage-services.sh status [service-name]

# Try rebuild
./scripts/manage-services.sh rebuild [service-name]
```

**High resource usage:**
```bash
# Check detailed status
./scripts/check-vps-status.sh --detailed

# View container resource usage
docker stats
```

**Network issues:**
```bash
# Check if ports are open
nc -zv localhost 8545  # RPC
nc -zv localhost 3000  # Grafana
nc -zv localhost 3002  # Faucet

# Check nginx configuration
docker exec axionax-nginx nginx -t

# Restart nginx
./scripts/manage-services.sh restart nginx
```

---

## 📊 Monitoring & Alerting

### Access Monitoring Dashboards

**Grafana:**
- URL: `http://YOUR_VPS_IP:3000`
- Username: `admin`
- Password: (from `.env` file)

**Prometheus:**
- URL: `http://YOUR_VPS_IP:9090`

### Key Metrics to Monitor

1. **RPC Node Health:**
   - Response time
   - Request rate
   - Error rate

2. **System Resources:**
   - RAM usage (should be < 90%)
   - Disk usage (should be < 90%)
   - CPU load

3. **Service Uptime:**
   - All services should show 99.9%+ uptime

---

## 🚨 Emergency Procedures

### Service Down

```bash
# Quick restart all services
./scripts/manage-services.sh restart all

# If that doesn't work, check status
./scripts/check-vps-status.sh --detailed

# Restart specific problematic service
./scripts/manage-services.sh rebuild [service-name]
```

### Database Issues

```bash
# Check database status
docker exec axionax-postgres pg_isready -U explorer

# View database logs
./scripts/manage-services.sh logs postgres

# Restart database (will cause brief downtime)
./scripts/manage-services.sh restart postgres
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean Docker resources
docker system prune -a --volumes

# Check logs size
du -sh /var/lib/docker/volumes/*

# Rotate logs
docker-compose -f docker-compose.vps.yml logs --no-log-prefix > /dev/null
```

---

## 📝 Logs & Debugging

### Log Locations

- **Deployment logs:** `/opt/axionax-deploy/deployment.log`
- **Service logs:** Via Docker Compose
- **System logs:** `/var/log/syslog`

### View Logs

```bash
# Real-time logs (all services)
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml logs -f

# Specific service
./scripts/manage-services.sh logs rpc-node

# Last 100 lines
docker-compose -f docker-compose.vps.yml logs --tail=100

# Since timestamp
docker-compose -f docker-compose.vps.yml logs --since 2024-01-01

# With grep filter
docker-compose -f docker-compose.vps.yml logs | grep ERROR
```

---

## ⚙️ Script Configuration

### Environment Variables

All scripts use the `.env` file in the deployment directory:

```env
# Database
DB_PASSWORD=your_secure_password

# Redis
REDIS_PASSWORD=your_redis_password

# Faucet
FAUCET_PRIVATE_KEY=0x...

# Monitoring
GRAFANA_PASSWORD=your_grafana_password

# Network
VPS_IP=217.216.109.5
DOMAIN=axionax.org  # Optional
```

### Resource Requirements

**Minimal Mode (4-8GB RAM):**
- RPC Node: 2-3GB RAM
- Faucet: 512MB RAM
- Infrastructure: 2GB RAM
- Total: ~5GB RAM

**Full Mode (8GB+ RAM):**
- All services: 6-8GB RAM
- Recommended: 16GB RAM for production

---

## 🔐 Security Notes

1. **Always use secure passwords** in `.env`
2. **Keep `.env` file private** (never commit to git)
3. **Configure firewall** (UFW installed by deployment script)
4. **Enable SSL certificates** for public domains
5. **Regular updates** of Docker images

---

## 🆘 Support

### Getting Help

1. **Check deployment logs:**
   ```bash
   tail -f /opt/axionax-deploy/deployment.log
   ```

2. **Run status check:**
   ```bash
   ./scripts/check-vps-status.sh --detailed
   ```

3. **View service logs:**
   ```bash
   ./scripts/manage-services.sh logs [service-name]
   ```

### Common Issues

| Issue | Solution |
|-------|----------|
| Service won't start | Check logs, verify .env variables, check disk space |
| High RAM usage | Restart services, consider upgrading VPS |
| SSL certificate errors | Re-run certbot, check domain DNS |
| Database connection errors | Restart postgres, check password in .env |
| Port already in use | Check for conflicting services, change ports |

---

## 📚 Additional Resources

- **Main README:** `../README.md`
- **VPS Deployment Guide:** `../VPS_DEPLOYMENT.md`
- **Docker Compose Config:** `../docker-compose.vps.yml`
- **Nginx Config:** `../nginx/`

---

## 🔄 Script Updates

These scripts are regularly updated. To get the latest version:

```bash
cd /opt/axionax-deploy
git pull origin main
chmod +x scripts/*.sh
```

---

**Last Updated:** November 12, 2025
**Version:** 1.0.0
**Maintainer:** axionax Protocol Team
