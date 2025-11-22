#!/bin/bash
# AxionAx Core - macOS Dependency Installation Script
# Installs Rust, Node.js, Python, and other required dependencies

set -e

echo "================================================"
echo "AxionAx Core - macOS Dependency Installer"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo -e "${GREEN}Homebrew installed successfully${NC}"
else
    echo -e "${GREEN}Homebrew already installed${NC}"
fi

# Update Homebrew
echo -e "\n${YELLOW}Updating Homebrew...${NC}"
brew update

# Install build tools
echo -e "\n${YELLOW}Installing build tools...${NC}"
xcode-select --install 2>/dev/null || echo "Xcode command line tools already installed"

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

# Install Node.js
if ! command -v node &> /dev/null; then
    echo -e "\n${YELLOW}Installing Node.js...${NC}"
    brew install node
    echo -e "${GREEN}Node.js installed successfully${NC}"
else
    echo -e "${GREEN}Node.js already installed: $(node --version)${NC}"
fi

# Install Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "\n${YELLOW}Installing Python 3...${NC}"
    brew install python3
    echo -e "${GREEN}Python 3 installed successfully${NC}"
else
    echo -e "${GREEN}Python 3 already installed: $(python3 --version)${NC}"
fi

# Install additional tools
echo -e "\n${YELLOW}Installing additional tools...${NC}"
brew install protobuf cmake openssl pkg-config

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
echo -e "1. Restart your terminal or run: source ~/.zshrc"
echo -e "2. Build the project: cargo build --release"
echo -e "3. Run tests: cargo test"
