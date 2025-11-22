# axionax p## 🆕 Latest Update (November 12, 2025)

🎉 **Monitoring Infrastructure Deployed & All Services Healthy!**

Production VPS now running with complete monitoring stack:

✅ **Infrastructure Status:**
- ✅ **9/9 Services Healthy** - All containers operational
- ✅ **Prometheus Metrics** - Collecting data from 8 services (Port 9090)
- ✅ **Grafana Dashboards** - Real-time monitoring (Port 3030)
- ✅ **Health Checks Fixed** - Accurate service**Part of the axionax protocol Ecosystem**

Built with 💜 by the axionax team

**Last Updated**: November 12, 2025 - Monitoring stack deployed, all services healthy ✅us reporting
- ✅ **SSL/TLS Configured** - Secure HTTPS on port 443

🔧 **Recent Improvements:**
- Fixed health check script for accurate monitoring
- Resolved Grafana port conflict (moved 3000 → 3030)
- Deployed Prometheus with 8 service scrape jobs
- All placeholder services properly detected

📊 **Current VPS Metrics:**
- RAM: 12% usage (7.8GB available)
- Disk: 17% usage (60GB available)
- Uptime: 6+ days
- All 9 Docker containers runningt Infrastructure 🚀

Production-ready deployment infrastructure for **axionax protocol** services.

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Protocol](https://img.shields.io/badge/Protocol-axionax-purple)](https://axionax.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/Status-Pre--Testnet-orange)](https://github.com/axionaxprotocol/axionax-core)

---

## ?? Latest Update (November 2025)

?? **Preparing Infrastructure for Public Testnet Launch!**

We're completing final preparations before public testnet:

? **Infrastructure Checklist:**
- ??? Monitoring & Alerting Setup (Prometheus + Grafana)
- ?? Load Testing & Performance Optimization
- ?? Backup & Disaster Recovery Plans
- ?? Security Hardening & SSL Configuration
- ?? Resource Scaling Strategy

?? **Active Development:**
- Security audits in progress
- Performance benchmarking ongoing
- Documentation being finalized

?? **Deployment Ready:** All scripts tested and validated for VPS deployment

---

## Overview

This repository contains everything needed to deploy the complete **axionax
Protocol** infrastructure stack on a VPS or cloud environment.

### Part of axionax Ecosystem

Deploys the full axionax protocol stack:

- **Protocol Node**: [`axionax-core`](https://github.com/axionaxprotocol/axionax-core) - axionax RPC node
- **Block Explorer**: Blockchain data visualization
- **Testnet Faucet**: AXX token distribution
- **Web Interface**: [`axionax-web`](https://github.com/axionaxprotocol/axionax-web) - Static frontend
- **Monitoring**: Prometheus + Grafana dashboards
- **Issue Tracker**: [`issue-manager`](https://github.com/axionaxprotocol/issue-manager) - Track deployment tasks

**GitHub Organization**: https://github.com/axionaxprotocol

**Pre-Testnet Status:** Infrastructure ready, final testing in progress

---

## What Gets Deployed

### axionax protocol Services

- **RPC Node (Port 8545/8546)** - Full axionax protocol node
  - HTTP JSON-RPC endpoint
  - WebSocket support
  - CORS enabled
  - Health monitoring
- **Block Explorer (Port 3001)** - Blockchain visualization
  - Real-time axionax block data
  - Transaction/block search
  - Account history
  - Network statistics
- **Testnet Faucet (Port 3002)** - Token distribution
  - AXX token distribution
  - Rate limiting (1 request/24h)
  - Configurable amounts
- **Monitoring Stack** - System health
  - Grafana dashboards (Port 3030) ✨ **NEW PORT**
  - Prometheus metrics (Port 9090)
  - Health checks for all 9 services
  - Real-time resource monitoring
  - axionax node health alerts

### Infrastructure Components

- Nginx reverse proxy with SSL/TLS
- PostgreSQL database for blockchain indexing
- Redis cache for performance
- Automatic Let's Encrypt certificates
- Docker containerization
- Systemd service management

## Quick Start

### 1. Clone Repository on VPS

```bash
ssh root@YOUR_VPS_IP
cd /opt
git clone https://github.com/axionaxprotocol/axionax-deploy.git
cd axionax-deploy
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Required variables:

```env
DB_PASSWORD=your_postgres_password
REDIS_PASSWORD=your_redis_password
FAUCET_PRIVATE_KEY=0x...
GRAFANA_PASSWORD=your_grafana_password
VPS_IP=YOUR_VPS_IP
DOMAIN=axionax.org
```

### 3. Run Setup Script

```bash
chmod +x setup-vps.sh
./setup-vps.sh
```

The script automatically:

- Installs Docker and Docker Compose
- Requests SSL certificates
- Starts all services
- Configures firewall

## Architecture

```

         Nginx Reverse Proxy (SSL)
    rpc.axionax.org | explorer.axionax.org
         faucet.axionax.org





  RPC   Explore  Faucet  Monitor
 :8545   :3001   :3002    :3000





    Postgre  Redis
      SQL    Cache

```

## Services

### RPC Node (Port 8545/8546)

- HTTP JSON-RPC endpoint
- WebSocket support
- CORS enabled for public access
- Health check: `https://rpc.axionax.org/health`

### Block Explorer (Port 3001)

- Real-time blockchain data
- Transaction/block search
- Account history
- PostgreSQL backed

### Testnet Faucet (Port 3002)

- AXX token distribution
- Rate limiting (1 request/24h per IP)
- Redis-backed queue
- Configurable amount

### Monitoring (Port 3030/9090)

- **Grafana** (Port 3030) - Visual dashboards
  - Pre-configured datasources
  - Auto-provisioned dashboards
  - Real-time service health
  - Resource usage graphs
- **Prometheus** (Port 9090) - Metrics collection
  - 8 service scrape jobs (15s intervals)
  - axionax-rpc, Explorer, Faucet metrics
  - Infrastructure monitoring (Postgres, Redis, Nginx)
- Node health alerts
- Resource usage tracking
- **All 9 services monitored and healthy** ✅

## Management Commands

### Check VPS Status

```bash
cd /opt/axionax-deploy
./scripts/check-vps-status.sh           # Quick summary
./scripts/check-vps-status.sh --detailed # Full details
```

**Health Check Output:**
- ✅ All 9 services status (Healthy/Unhealthy)
- System resources (RAM, CPU, Disk)
- Docker container status
- Port availability checks

### View logs

```bash
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml logs -f [service-name]
```

### Restart services

```bash
docker-compose -f docker-compose.vps.yml restart
```

### Stop all services

```bash
docker-compose -f docker-compose.vps.yml down
```

### Update images

```bash
docker-compose -f docker-compose.vps.yml pull
docker-compose -f docker-compose.vps.yml up -d
```

### Backup database

```bash
docker exec axionax-postgres pg_dump -U explorer explorer > backup.sql
```

## DNS Configuration

Point these subdomains to your VPS IP:

```
Type: A, Name: rpc, Value: YOUR_VPS_IP
Type: A, Name: explorer, Value: YOUR_VPS_IP
Type: A, Name: faucet, Value: YOUR_VPS_IP
Type: A, Name: api, Value: YOUR_VPS_IP
```

## Security Features

- Automatic SSL/TLS via Let's Encrypt
- Security headers (HSTS, X-Frame-Options, CSP)
- Rate limiting on API endpoints
- Firewall configuration (UFW)
- Non-root container users
- Secret management via .env

## Monitoring Access

- **Grafana**: http://YOUR_VPS_IP:3030 ✨ **Updated Port**
  - Username: `admin`
  - Password: (from .env GRAFANA_PASSWORD)
  - Pre-configured Prometheus datasource
  - Auto-provisioned dashboards
- **Prometheus**: http://YOUR_VPS_IP:9090
  - Metrics explorer
  - Service health endpoints
  - 8 scrape job configurations

### Service Health Endpoints

All services have health check endpoints:

```bash
# RPC Node
curl http://YOUR_VPS_IP:8545/health

# Prometheus
curl http://YOUR_VPS_IP:9090/-/healthy

# Grafana
curl http://YOUR_VPS_IP:3030/api/health

# Check all services
cd /opt/axionax-deploy
./scripts/check-vps-status.sh
```

## Repository Structure

```
.
 docker-compose.vps.yml    # Main service definitions
 setup-vps.sh              # Automated setup script
 .env.example              # Environment template
 nginx/
    nginx.conf            # Main Nginx config
    conf.d/               # Site configurations
        rpc.conf          # RPC proxy
        explorer.conf     # Explorer proxy
        faucet.conf       # Faucet proxy
 monitoring/
    prometheus.yml        # Metrics config
    grafana/              # Dashboards
 VPS_DEPLOYMENT.md         # Detailed guide

```

## CI/CD Integration

Services auto-deploy when new images are pushed to GitHub Container Registry:

```bash
# Pull latest images
docker-compose -f docker-compose.vps.yml pull

# Recreate containers
docker-compose -f docker-compose.vps.yml up -d
```

## Requirements

### Minimum Requirements (Testing)

- Ubuntu 20.04+ or Debian 11+
- **4GB RAM**, 2 CPU cores
- 50GB+ SSD storage
- Root or sudo access
- Domain with DNS access

### Recommended for Pre-Testnet (Current Phase)

- Ubuntu 22.04 LTS
- **8GB RAM**, 4 CPU cores
- 100GB NVMe SSD
- 2TB+ bandwidth/month
- Dedicated IP
- Cost: ~$20-40/month

### Production Testnet (After Launch)

- Ubuntu 22.04 LTS
- **16GB RAM**, 8 CPU cores
- 200GB NVMe SSD
- 4TB+ bandwidth/month
- DDoS protection
- Cost: ~$60-100/month

## Pre-Launch Checklist

Use our [Issue Manager](../issue-manager) to track:

- [ ] ??? Infrastructure monitoring setup
- [ ] ?? Load testing completed
- [ ] ?? Backup systems verified
- [ ] ?? Security audit passed
- [ ] ?? Scaling strategy tested
- [ ] ?? Documentation complete

## Documentation

- **[VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md)** - Complete deployment guide
- **[TESTNET_LAUNCH_CHECKLIST.md](TESTNET_LAUNCH_CHECKLIST.md)** - Pre-launch checklist
- **[GITHUB_PAGES_SETUP.md](GITHUB_PAGES_SETUP.md)** - Website hosting setup

## axionax protocol Ecosystem

| Component         | Description               | Location                                         | Status     |
| ----------------- | ------------------------- | ------------------------------------------------ | ---------- |
| **Deploy** (this) | Infrastructure deployment | `axionax-deploy/`                                | ?? Testing |
| **Core**          | axionax protocol node     | [`../axionax-core`](../axionax-core)             | ✅ Ready   |
| **Web**           | Frontend interface        | [`../axionax-web`](../axionax-web)               | ? Ready   |
| **SDK**           | Developer SDK             | [`../axionax-sdk-ts`](../axionax-sdk-ts)         | ? Ready   |
| **Docs**          | Documentation             | [`../axionax-docs`](../axionax-docs)             | ?? Active  |
| **DevTools**      | Development tools         | [`../axionax-devtools`](../axionax-devtools)     | ? Ready   |
| **Marketplace**   | Compute marketplace       | [`../axionax-marketplace`](../axionax-marketplace) | ?? Beta  |
| **Issue Manager** | Task tracking             | [`../issue-manager`](../issue-manager)           | ?? New!    |

---

## Related Projects

### Core Components

- **[Protocol Core](../axionax-core)** - axionax blockchain implementation
- **[Web Interface](../axionax-web)** - Frontend (deployed separately)
- **[SDK](../axionax-sdk-ts)** - Used by Explorer/Faucet APIs
- **[Documentation](../axionax-docs)** - Full protocol documentation

### External Resources

- **GitHub Organization**: https://github.com/axionaxprotocol
- **Protocol Website**: https://axionax.org
- **Documentation**: https://docs.axionax.org

---

## Contributing

1. Fork the repository:
   [axionaxprotocol/axionax-deploy](https://github.com/axionaxprotocol/axionax-deploy)
2. Create feature branch
3. Test changes with Docker Compose locally
4. Submit pull request

---

## License

MIT License - see [LICENSE](LICENSE) for details.

**Note**: The axionax protocol Core uses AGPLv3. See
[`../axionax-core/LICENSE`](../axionax-core/LICENSE).

---

## Support

- **Issues**: https://github.com/axionaxprotocol/axionax-deploy/issues
- **Docs**: https://docs.axionax.org or [`axionax-docs`](https://github.com/axionaxprotocol/axionax-docs)
- **GitHub Organization**: https://github.com/axionaxprotocol

### Community (Coming Q1 2026)

- **Discord**: https://discord.gg/axionax
- **Twitter**: https://twitter.com/axionaxprotocol

---

**Part of the axionax protocol Ecosystem**

Built with ?? by the axionax team

**Last Updated**: November 7, 2025
