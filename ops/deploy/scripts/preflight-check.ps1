# ==============================================================================
# axionax VPS Deployment - Simple Pre-Flight Check
# ==============================================================================

Write-Host "`n=== axionax VPS Deployment Pre-Flight Check ===" -ForegroundColor Cyan

$DeployDir = "C:\Users\engnc\axionaxius02\axionax-deploy"
$VPS_IP = "217.216.109.5"

# 1. Check Scripts
Write-Host "`n[1] Checking Scripts..." -ForegroundColor Yellow
$scripts = @("deploy-all-services.sh", "check-vps-status.sh", "manage-services.sh")
foreach ($script in $scripts) {
    if (Test-Path "$DeployDir\scripts\$script") {
        Write-Host "  OK: $script" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $script" -ForegroundColor Red
    }
}

# 2. Check Docker Compose
Write-Host "`n[2] Checking Docker Compose..." -ForegroundColor Yellow
if (Test-Path "$DeployDir\docker-compose.vps.yml") {
    Write-Host "  OK: docker-compose.vps.yml exists" -ForegroundColor Green
} else {
    Write-Host "  MISSING: docker-compose.vps.yml" -ForegroundColor Red
}

# 3. Check Environment
Write-Host "`n[3] Checking Environment..." -ForegroundColor Yellow
if (Test-Path "$DeployDir\.env") {
    Write-Host "  WARNING: .env exists (will be used)" -ForegroundColor Yellow
} else {
    Write-Host "  NOTE: .env not found (create from .env.example on VPS)" -ForegroundColor Cyan
}

if (Test-Path "$DeployDir\.env.example") {
    Write-Host "  OK: .env.example exists" -ForegroundColor Green
} else {
    Write-Host "  MISSING: .env.example" -ForegroundColor Red
}

# 4. Check Documentation
Write-Host "`n[4] Checking Documentation..." -ForegroundColor Yellow
$docs = @("README.md", "scripts\README.md", "scripts\QUICK_REFERENCE.md")
foreach ($doc in $docs) {
    if (Test-Path "$DeployDir\$doc") {
        Write-Host "  OK: $doc" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $doc" -ForegroundColor Yellow
    }
}

# 5. Test VPS Connection
Write-Host "`n[5] Testing VPS Connection ($VPS_IP)..." -ForegroundColor Yellow

# Ping test
if (Test-Connection -ComputerName $VPS_IP -Count 2 -Quiet) {
    Write-Host "  OK: VPS is reachable (ping)" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Ping failed (might be firewalled)" -ForegroundColor Yellow
}

# SSH test
$sshTest = Test-NetConnection -ComputerName $VPS_IP -Port 22 -WarningAction SilentlyContinue
if ($sshTest.TcpTestSucceeded) {
    Write-Host "  OK: SSH (port 22) is accessible" -ForegroundColor Green
} else {
    Write-Host "  ERROR: SSH (port 22) not accessible!" -ForegroundColor Red
}

# HTTP test
try {
    $null = Invoke-WebRequest -Uri "http://$VPS_IP" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  OK: HTTP (port 80) is accessible" -ForegroundColor Green
} catch {
    Write-Host "  NOTE: HTTP (port 80) not accessible yet" -ForegroundColor Cyan
}

# HTTPS test  
$httpsTest = Test-NetConnection -ComputerName $VPS_IP -Port 443 -WarningAction SilentlyContinue
if ($httpsTest.TcpTestSucceeded) {
    Write-Host "  OK: HTTPS (port 443) is accessible" -ForegroundColor Green
} else {
    Write-Host "  NOTE: HTTPS (port 443) not accessible yet" -ForegroundColor Cyan
}

# Grafana test
$grafanaTest = Test-NetConnection -ComputerName $VPS_IP -Port 3000 -WarningAction SilentlyContinue
if ($grafanaTest.TcpTestSucceeded) {
    Write-Host "  OK: Grafana (port 3000) is accessible" -ForegroundColor Green
} else {
    Write-Host "  NOTE: Grafana not running yet" -ForegroundColor Cyan
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Pre-flight check complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to VPS: ssh root@$VPS_IP" -ForegroundColor White
Write-Host "2. Upload files or clone repo to /opt/axionax-deploy" -ForegroundColor White
Write-Host "3. Configure .env file" -ForegroundColor White
Write-Host "4. Run: chmod +x scripts/*.sh" -ForegroundColor White
Write-Host "5. Run: sudo ./scripts/deploy-all-services.sh --check-only" -ForegroundColor White
Write-Host "6. Run: sudo ./scripts/deploy-all-services.sh --full" -ForegroundColor White

# Save connection commands
$connectionInfo = @"
# axionax VPS Quick Commands
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Connect to VPS
ssh root@$VPS_IP

# Upload files (run from parent directory)
scp -r axionax-deploy root@${VPS_IP}:/opt/

# OR clone from GitHub (on VPS)
cd /opt
git clone https://github.com/axionaxprotocol/axionax-deploy.git
cd axionax-deploy

# Setup
cp .env.example .env
nano .env
chmod +x scripts/*.sh

# Deploy
sudo ./scripts/deploy-all-services.sh --check-only
sudo ./scripts/deploy-all-services.sh --full

# Manage
./scripts/check-vps-status.sh
./scripts/manage-services.sh logs rpc-node
./scripts/manage-services.sh restart all
"@

$connectionInfo | Out-File -FilePath "$DeployDir\VPS_CONNECTION.txt" -Encoding UTF8
Write-Host "`nConnection commands saved to: VPS_CONNECTION.txt" -ForegroundColor Cyan
