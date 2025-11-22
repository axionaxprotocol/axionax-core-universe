#!/bin/bash
# AxionAx Core - Linux Dependency Installation Script
# Installs Rust, Node.js, Python, and other required dependencies

set -e

echo "================================================"
echo "AxionAx Core - Linux Dependency Installer"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root${NC}"
    exit 1
fi

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
fi

echo -e "${GREEN}Detected OS: $OS $VER${NC}"

# Update package manager
echo -e "\n${YELLOW}Updating package manager...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get update
elif command -v dnf &> /dev/null; then
    sudo dnf check-update || true
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy
fi

# Install build essentials
echo -e "\n${YELLOW}Installing build essentials...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get install -y build-essential pkg-config libssl-dev curl git
elif command -v dnf &> /dev/null; then
    sudo dnf install -y gcc gcc-c++ make pkgconfig openssl-devel curl git
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm base-devel openssl curl git
fi

# Install Rust
if ! command -v rustc &> /dev/null; then
    echo -e "\n${YELLOW}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo -e "${GREEN}Rust installed successfully${NC}"
else
    echo -e "${GREEN}Rust already installed: $(rustc --version)${NC}"
fi

# Update Rust
echo -e "\n${YELLOW}Updating Rust...${NC}"
rustup update

# Install Node.js (via nvm)
if ! command -v node &> /dev/null; then
    echo -e "\n${YELLOW}Installing Node.js...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    echo -e "${GREEN}Node.js installed successfully${NC}"
else
    echo -e "${GREEN}Node.js already installed: $(node --version)${NC}"
fi

# Install Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "\n${YELLOW}Installing Python 3...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm python python-pip
    fi
    echo -e "${GREEN}Python 3 installed successfully${NC}"
else
    echo -e "${GREEN}Python 3 already installed: $(python3 --version)${NC}"
fi

# Install additional tools
echo -e "\n${YELLOW}Installing additional tools...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get install -y protobuf-compiler cmake
elif command -v dnf &> /dev/null; then
    sudo dnf install -y protobuf-compiler cmake
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm protobuf cmake
fi

# Install Rust components
echo -e "\n${YELLOW}Installing Rust components...${NC}"
rustup component add rustfmt clippy

# Install npm packages
if [ -f "package.json" ]; then
    echo -e "\n${YELLOW}Installing npm packages...${NC}"
    npm install
fi

# Install Python packages
if [ -f "requirements.txt" ]; then
    echo -e "\n${YELLOW}Installing Python packages...${NC}"
    pip3 install --user -r requirements.txt
elif [ -f "pyproject.toml" ]; then
    echo -e "\n${YELLOW}Installing Python packages from pyproject.toml...${NC}"
    pip3 install --user -e .
fi

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nNext steps:"
echo -e "1. Restart your terminal or run: source ~/.bashrc"
echo -e "2. Build the project: cargo build --release"
echo -e "3. Run tests: cargo test"
