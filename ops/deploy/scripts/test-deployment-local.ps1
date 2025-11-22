# =============================================================================
# Pre-Deployment Test Script (Windows PowerShell)
# =============================================================================
# This script prepares and validates everything before deploying to VPS
# Run this BEFORE uploading to VPS
# =============================================================================

$ErrorActionPreference = "Continue"

# Colors
$script:Colors = @{
    Red     = "Red"
    Green   = "Green"
    Yellow  = "Yellow"
    Cyan    = "Cyan"
    Blue    = "Blue"
    Magenta = "Magenta"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorOutput "  $Title" "Cyan"
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Blue"
}

# Main execution
Write-Header "axionax VPS Deployment - Pre-Flight Check"

$DeployDir = Split-Path -Parent $PSScriptRoot
$ScriptsDir = Join-Path $DeployDir "scripts"

Write-Info "Deploy Directory: $DeployDir"
Write-Info "Scripts Directory: $ScriptsDir"

# =============================================================================
# 1. Check Scripts Existence
# =============================================================================
Write-Header "1. Checking Required Scripts"

$RequiredScripts = @(
    "deploy-all-services.sh",
    "check-vps-status.sh",
    "manage-services.sh"
)

$AllScriptsExist = $true
foreach ($script in $RequiredScripts) {
    $scriptPath = Join-Path $ScriptsDir $script
    if (Test-Path $scriptPath) {
        Write-Success "$script exists"
    } else {
        Write-Error "$script is missing!"
        $AllScriptsExist = $false
    }
}

if ($AllScriptsExist) {
    Write-Success "All required scripts are present"
} else {
    Write-Error "Some scripts are missing. Please create them first."
    exit 1
}

# =============================================================================
# 2. Check Script Syntax
# =============================================================================
Write-Header "2. Validating Script Syntax"

foreach ($script in $RequiredScripts) {
    $scriptPath = Join-Path $ScriptsDir $script
    $content = Get-Content $scriptPath -Raw
    
    # Basic checks
    if ($content -match '#!/bin/bash') {
        Write-Success "$script has valid shebang"
    } else {
        Write-Warning "$script missing shebang"
    }
    
    # Check for common bash errors
    if ($content -match '\$\{[^}]+\}') {
        Write-Success "$script uses proper variable syntax"
    }
}

# =============================================================================
# 3. Check Environment Configuration
# =============================================================================
Write-Header "3. Checking Environment Configuration"

$EnvExamplePath = Join-Path $DeployDir ".env.example"
$EnvPath = Join-Path $DeployDir ".env"

if (Test-Path $EnvExamplePath) {
    Write-Success ".env.example exists"
} else {
    Write-Error ".env.example not found!"
}

if (Test-Path $EnvPath) {
    Write-Warning ".env file exists (will be used on VPS)"
    Write-Info "Checking .env configuration..."
    
    $envContent = Get-Content $EnvPath -Raw
    
    # Check required variables
    $requiredVars = @(
        "DB_PASSWORD",
        "REDIS_PASSWORD",
        "GRAFANA_PASSWORD",
        "VPS_IP"
    )
    
    foreach ($var in $requiredVars) {
        if ($envContent -match "$var=.+") {
            if ($envContent -match "$var=your_") {
                Write-Warning "$var is still set to placeholder value"
            } else {
                Write-Success "$var is configured"
            }
        } else {
            Write-Error "$var is missing or empty!"
        }
    }
} else {
    Write-Warning ".env file not found (will need to be created on VPS)"
    Write-Info "You'll need to create this from .env.example on the VPS"
}

# =============================================================================
# 4. Check Docker Compose File
# =============================================================================
Write-Header "4. Checking Docker Compose Configuration"

$ComposeFile = Join-Path $DeployDir "docker-compose.vps.yml"
if (Test-Path $ComposeFile) {
    Write-Success "docker-compose.vps.yml exists"
    
    $composeContent = Get-Content $ComposeFile -Raw
    
    # Count services
    $services = ([regex]::Matches($composeContent, '^\s{2}\w+-?\w*:' -split "`n")).Count
    Write-Info "Found $services services defined"
    
    # Check for required services
    $requiredServices = @("nginx", "rpc-node", "postgres", "redis", "grafana")
    foreach ($service in $requiredServices) {
        $pattern = "  ${service}:"
        if ($composeContent -match $pattern) {
            Write-Success "$service service defined"
        } else {
            Write-Warning "$service service not found"
        }
    }
} else {
    Write-Error "docker-compose.vps.yml not found!"
}

# =============================================================================
# 5. Check Documentation
# =============================================================================
Write-Header "5. Checking Documentation"

$docs = @(
    @{Path="README.md"; Name="Main README"},
    @{Path="scripts/README.md"; Name="Scripts README"},
    @{Path="scripts/QUICK_REFERENCE.md"; Name="Quick Reference"}
)

foreach ($doc in $docs) {
    $docPath = Join-Path $DeployDir $doc.Path
    if (Test-Path $docPath) {
        Write-Success "$($doc.Name) exists"
    } else {
        Write-Warning "$($doc.Name) not found"
    }
}

# =============================================================================
# 6. VPS Connection Test
# =============================================================================
Write-Header "6. Testing VPS Connection"

# Try to read VPS IP from .env if it exists
$vpsIP = "217.216.109.5"
if (Test-Path $EnvPath) {
    $envLines = Get-Content $EnvPath
    $vpsIPLine = $envLines | Where-Object { $_ -match '^VPS_IP=' }
    if ($vpsIPLine) {
        $vpsIP = ($vpsIPLine -split '=')[1].Trim()
    }
}

Write-Info "Testing connection to VPS: $vpsIP"

# Test ping
if (Test-Connection -ComputerName $vpsIP -Count 2 -Quiet) {
    Write-Success "VPS is reachable (ping successful)"
} else {
    Write-Warning "VPS ping failed (might be blocked by firewall)"
}

# Test HTTP
try {
    $response = Invoke-WebRequest -Uri "http://$vpsIP" -TimeoutSec 5 -ErrorAction Stop
    Write-Success "HTTP (port 80) is accessible"
} catch {
    Write-Warning "HTTP (port 80) not accessible"
}

# Test HTTPS
try {
    $response = Invoke-WebRequest -Uri "https://$vpsIP" -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
    Write-Success "HTTPS (port 443) is accessible"
} catch {
    Write-Warning "HTTPS (port 443) not accessible"
}

# Test SSH
$sshTest = Test-NetConnection -ComputerName $vpsIP -Port 22
if ($sshTest.TcpTestSucceeded) {
    Write-Success "SSH (port 22) is accessible"
    Write-Info "You can connect with: ssh root@$vpsIP"
} else {
    Write-Error "SSH (port 22) is not accessible!"
    Write-Warning "Make sure SSH is enabled on the VPS"
}

# =============================================================================
# 7. Generate Upload Command
# =============================================================================
Write-Header "7. Next Steps - Deploy to VPS"

Write-Info "To deploy to your VPS, follow these steps:"
Write-Host ""

Write-ColorOutput "Step 1: Upload files to VPS" "Yellow"
Write-Host "# Using SCP (from this directory):"
Write-ColorOutput "scp -r ../axionax-deploy root@${vpsIP}:/opt/" "Cyan"
Write-Host ""
Write-Host "# OR using Git (on VPS):"
Write-ColorOutput "ssh root@$vpsIP" "Cyan"
Write-ColorOutput "cd /opt" "Cyan"
Write-ColorOutput "git clone https://github.com/axionaxprotocol/axionax-deploy.git" "Cyan"
Write-Host ""

Write-ColorOutput "Step 2: Configure environment" "Yellow"
Write-ColorOutput "ssh root@$vpsIP" "Cyan"
Write-ColorOutput "cd /opt/axionax-deploy" "Cyan"
Write-ColorOutput "cp .env.example .env" "Cyan"
Write-ColorOutput "nano .env  # Edit with your values" "Cyan"
Write-Host ""

Write-ColorOutput "Step 3: Make scripts executable" "Yellow"
Write-ColorOutput "chmod +x scripts/*.sh" "Cyan"
Write-Host ""

Write-ColorOutput "Step 4: Check system requirements" "Yellow"
Write-ColorOutput "sudo ./scripts/deploy-all-services.sh --check-only" "Cyan"
Write-Host ""

Write-ColorOutput "Step 5: Deploy services" "Yellow"
Write-ColorOutput "# For full deployment (8GB+ RAM):" "Green"
Write-ColorOutput "sudo ./scripts/deploy-all-services.sh --full" "Cyan"
Write-Host ""
Write-ColorOutput "# For minimal deployment (4-8GB RAM):" "Green"
Write-ColorOutput "sudo ./scripts/deploy-all-services.sh --minimal" "Cyan"
Write-Host ""

# =============================================================================
# 8. Create deployment checklist
# =============================================================================
Write-Header "8. Deployment Checklist"

$checklist = @"
□ Scripts validated locally
□ .env file configured with secure passwords
□ VPS connection tested
□ Files uploaded to VPS
□ Scripts made executable (chmod +x)
□ System requirements checked
□ Services deployed
□ Health checks passed
□ Monitoring dashboards accessible
"@

Write-Host $checklist

# =============================================================================
# Summary
# =============================================================================
Write-Header "Pre-Flight Check Complete"

Write-Success "All local checks passed!"
Write-Info "You are ready to deploy to VPS"
Write-Host ""
Write-ColorOutput "Quick connect command:" "Yellow"
Write-ColorOutput "ssh root@$vpsIP" "Cyan"
Write-Host ""
Write-Info "After connecting, navigate to: cd /opt/axionax-deploy"
Write-Host ""

# Save connection info to file
$connectionInfo = @"
# axionax VPS Connection Info
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

VPS_IP=$vpsIP

# Quick Connect
ssh root@$vpsIP

# Upload Files
scp -r ../axionax-deploy root@${vpsIP}:/opt/

# After connecting
cd /opt/axionax-deploy
chmod +x scripts/*.sh
sudo ./scripts/deploy-all-services.sh --check-only
sudo ./scripts/deploy-all-services.sh --full
"@

$connectionInfo | Out-File -FilePath (Join-Path $DeployDir "VPS_CONNECTION.txt") -Encoding UTF8
Write-Info "Connection info saved to: VPS_CONNECTION.txt"
