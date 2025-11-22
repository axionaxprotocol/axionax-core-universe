# axionax Protocol - VPS Quick Reference Card

## 🚀 Essential Commands

### Start Services
```bash
# Deploy all services (first time)
sudo ./scripts/deploy-all-services.sh --full

# Start all services
./scripts/manage-services.sh start all

# Start specific service
./scripts/manage-services.sh start rpc-node
```

### Check Status
```bash
# Quick status
./scripts/check-vps-status.sh

# Detailed status
./scripts/check-vps-status.sh --detailed

# Specific service
./scripts/manage-services.sh status rpc-node
```

### View Logs
```bash
# All services
cd /opt/axionax-deploy && docker-compose -f docker-compose.vps.yml logs -f

# Specific service
./scripts/manage-services.sh logs faucet

# Last 100 lines
docker-compose -f docker-compose.vps.yml logs --tail=100 rpc-node
```

### Restart Services
```bash
# Restart all
./scripts/manage-services.sh restart all

# Restart specific service
./scripts/manage-services.sh restart nginx
```

### Stop Services
```bash
# Stop all
./scripts/manage-services.sh stop all

# Stop specific service
./scripts/manage-services.sh stop explorer-backend
```

---

## 📊 Service Endpoints

### Public Access
- **Website:** `http://217.216.109.5`
- **HTTPS:** `https://217.216.109.5`
- **Grafana:** `http://217.216.109.5:3000`

### With Domain (if DNS configured)
- **RPC:** `https://rpc.axionax.org`
- **Explorer:** `https://explorer.axionax.org`
- **Faucet:** `https://faucet.axionax.org`

### Direct Access (No SSL)
- **RPC HTTP:** `http://217.216.109.5:8545`
- **RPC WS:** `ws://217.216.109.5:8546`
- **Explorer API:** `http://217.216.109.5:3001`
- **Faucet API:** `http://217.216.109.5:3002`
- **Prometheus:** `http://217.216.109.5:9090`

---

## 🔧 Troubleshooting

### Service Not Responding
```bash
# Check status
./scripts/check-vps-status.sh

# View logs
./scripts/manage-services.sh logs [service-name]

# Restart service
./scripts/manage-services.sh restart [service-name]

# Rebuild if needed
./scripts/manage-services.sh rebuild [service-name]
```

### High Resource Usage
```bash
# Check resources
./scripts/check-vps-status.sh --detailed

# View container stats
docker stats

# Restart heavy service
./scripts/manage-services.sh restart rpc-node
```

### Database Issues
```bash
# Check database
docker exec axionax-postgres pg_isready -U explorer

# View logs
./scripts/manage-services.sh logs postgres

# Restart database
./scripts/manage-services.sh restart postgres
```

### Network/Port Issues
```bash
# Check if port is open
nc -zv localhost 8545

# Check nginx config
docker exec axionax-nginx nginx -t

# Restart nginx
./scripts/manage-services.sh restart nginx
```

---

## 📋 Service Names

| Service Name | Description | Port(s) |
|--------------|-------------|---------|
| `nginx` | Web server | 80, 443 |
| `rpc-node` | Blockchain RPC | 8545, 8546 |
| `explorer-backend` | Explorer API | 3001 |
| `faucet` | Token faucet | 3002 |
| `grafana` | Dashboard | 3000 |
| `prometheus` | Metrics | 9090 |
| `postgres` | Database | 5432 |
| `redis` | Cache | 6379 |
| `certbot` | SSL certs | - |

---

## 🔄 Maintenance Commands

### Update Services
```bash
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml pull
./scripts/manage-services.sh restart all
```

### Backup Database
```bash
docker exec axionax-postgres pg_dump -U explorer explorer > backup.sql
```

### Clean Docker
```bash
# Remove unused containers/images
docker system prune -a

# Free up space
docker volume prune
```

### View Disk Usage
```bash
# Overall
df -h

# Docker
docker system df

# Volumes
du -sh /var/lib/docker/volumes/*
```

---

## 📞 Quick Checks

```bash
# Are services running?
docker ps

# What's using resources?
docker stats

# Any errors recently?
docker-compose -f docker-compose.vps.yml logs --since 1h | grep -i error

# System resources
free -h && df -h
```

---

## 🆘 Emergency

### Everything is down
```bash
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml down
docker-compose -f docker-compose.vps.yml up -d
./scripts/check-vps-status.sh
```

### Out of space
```bash
docker system prune -a --volumes
```

### Need to restart VPS
```bash
# Stop services gracefully first
./scripts/manage-services.sh stop all
sudo reboot

# After reboot
./scripts/manage-services.sh start all
```

---

## 📍 File Locations

- **Scripts:** `/opt/axionax-deploy/scripts/`
- **Config:** `/opt/axionax-deploy/.env`
- **Logs:** `/opt/axionax-deploy/deployment.log`
- **Compose:** `/opt/axionax-deploy/docker-compose.vps.yml`

---

**Keep this card handy for quick reference!** 🚀
