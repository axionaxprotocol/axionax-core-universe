# AxionAx Core - Windows Dependency Installation Script
# Installs Rust, Node.js, Python, and other required dependencies

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "AxionAx Core - Windows Dependency Installer" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Running without administrator privileges. Some installations may fail." -ForegroundColor Yellow
}

# Install Chocolatey if not present
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalling Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed successfully" -ForegroundColor Green
} else {
    Write-Host "Chocolatey already installed" -ForegroundColor Green
}

# Install Visual Studio Build Tools (required for Rust)
Write-Host "`nChecking for Visual Studio Build Tools..." -ForegroundColor Yellow
if (-not (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019") -and 
    -not (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2022")) {
    Write-Host "Installing Visual Studio Build Tools (this may take a while)..." -ForegroundColor Yellow
    choco install visualstudio2022buildtools -y --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --includeOptional"
} else {
    Write-Host "Visual Studio Build Tools already installed" -ForegroundColor Green
}

# Install Rust
if (-not (Get-Command rustc -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalling Rust..." -ForegroundColor Yellow
    choco install rust -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Rust installed successfully" -ForegroundColor Green
} else {
    Write-Host "Rust already installed: $(rustc --version)" -ForegroundColor Green
}

# Update Rust
Write-Host "`nUpdating Rust..." -ForegroundColor Yellow
rustup update

# Install Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalling Node.js..." -ForegroundColor Yellow
    choco install nodejs-lts -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Node.js installed successfully" -ForegroundColor Green
} else {
    Write-Host "Node.js already installed: $(node --version)" -ForegroundColor Green
}

# Install Python 3
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalling Python 3..." -ForegroundColor Yellow
    choco install python3 -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Python 3 installed successfully" -ForegroundColor Green
} else {
    Write-Host "Python 3 already installed: $(python --version)" -ForegroundColor Green
}

# Install Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalling Git..." -ForegroundColor Yellow
    choco install git -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Git installed successfully" -ForegroundColor Green
} else {
    Write-Host "Git already installed: $(git --version)" -ForegroundColor Green
}

# Install CMake and Protobuf
Write-Host "`nInstalling additional tools..." -ForegroundColor Yellow
choco install cmake -y
choco install protoc -y
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Rust components
Write-Host "`nInstalling Rust components..." -ForegroundColor Yellow
rustup component add rustfmt clippy

# Install npm packages
if (Test-Path "package.json") {
    Write-Host "`nInstalling npm packages..." -ForegroundColor Yellow
    npm install
}

# Install Python packages
if (Test-Path "requirements.txt") {
    Write-Host "`nInstalling Python packages..." -ForegroundColor Yellow
    python -m pip install --user -r requirements.txt
} elseif (Test-Path "pyproject.toml") {
    Write-Host "`nInstalling Python packages from pyproject.toml..." -ForegroundColor Yellow
    python -m pip install --user -e .
}

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "`nNext steps:"
Write-Host "1. Restart your terminal/PowerShell"
Write-Host "2. Build the project: cargo build --release"
Write-Host "3. Run tests: cargo test"
