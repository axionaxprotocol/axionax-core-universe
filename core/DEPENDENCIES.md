# Dependencies Installation Guide - AxionAx Core

Complete guide for installing all required dependencies for AxionAx Protocol development.

## 📋 Dependency Checklist

### Required (Core Development)
- ✅ **Rust** 1.75+ with Cargo
- ✅ **Python** 3.10+
- ✅ **Git** 2.30+
- ✅ **Node.js** 18+ with npm
- ✅ **PostgreSQL** 14+
- ✅ **Redis** 6+

### Optional (Enhanced Development)
- 🔧 **Docker** 20+ with Docker Compose
- 🔧 **Prometheus** 2.40+ (monitoring)
- 🔧 **jq** (JSON processing)
- 🔧 **Cargo tools**: cargo-tarpaulin, cargo-audit, cargo-clippy

---

## 🪟 Windows Installation

### Automated Installation

```powershell
# Run the automated installer
.\install_dependencies_windows.ps1
```

### Manual Installation

#### 1. Rust
```powershell
# Download and run rustup installer
# Visit: https://rustup.rs
# Or use winget:
winget install Rustlang.Rustup

# Verify installation
rustc --version
cargo --version
```

#### 2. Python
```powershell
# Using winget
winget install Python.Python.3.12

# Or download from python.org
# https://www.python.org/downloads/

# Verify installation
python --version
pip --version
```

#### 3. Node.js
```powershell
# Using winget
winget install OpenJS.NodeJS.LTS

# Or download from nodejs.org
# https://nodejs.org/

# Verify installation
node --version
npm --version
```

#### 4. Git
```powershell
# Using winget
winget install Git.Git

# Verify installation
git --version
```

#### 5. PostgreSQL
```powershell
# Using winget
winget install PostgreSQL.PostgreSQL

# Or use installer:
# https://www.postgresql.org/download/windows/

# Verify installation
psql --version
```

#### 6. Redis
```powershell
# Option 1: WSL2 + Ubuntu
wsl --install
wsl sudo apt update
wsl sudo apt install redis-server

# Option 2: Memurai (Windows-native Redis)
winget install Memurai.Memurai-Developer

# Verify installation
redis-cli --version
```

#### 7. Docker (Optional)
```powershell
# Install Docker Desktop
winget install Docker.DockerDesktop

# Verify installation
docker --version
docker-compose --version
```

#### 8. Cargo Tools
```powershell
# Install useful cargo tools
cargo install cargo-tarpaulin  # Code coverage
cargo install cargo-audit      # Security audit
cargo install cargo-watch      # File watcher

# Update components
rustup component add clippy    # Linter
rustup component add rustfmt   # Formatter
```

---

## 🐧 Linux Installation (Ubuntu/Debian)

### Automated Installation

```bash
# Run the automated installer
chmod +x install_dependencies_linux.sh
./install_dependencies_linux.sh
```

### Manual Installation

#### 1. Rust
```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

#### 2. Python
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3.11 python3-pip python3-venv -y

# Verify installation
python3 --version
pip3 --version
```

#### 3. Node.js
```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y

# Verify installation
node --version
npm --version
```

#### 4. Git
```bash
# Install Git
sudo apt install git -y

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify installation
git --version
```

#### 5. PostgreSQL
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create user and database
sudo -u postgres createuser axionax
sudo -u postgres createdb axionax_testnet

# Verify installation
psql --version
```

#### 6. Redis
```bash
# Install Redis
sudo apt install redis-server -y

# Start Redis service
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify installation
redis-cli --version
```

#### 7. Docker (Optional)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

#### 8. Build Tools
```bash
# Essential build tools
sudo apt install build-essential pkg-config libssl-dev -y

# Additional libraries
sudo apt install libpq-dev libclang-dev -y
```

#### 9. Cargo Tools
```bash
# Install cargo tools
cargo install cargo-tarpaulin
cargo install cargo-audit
cargo install cargo-watch

# Update components
rustup component add clippy
rustup component add rustfmt
```

---

## 🍎 macOS Installation

### Automated Installation

```bash
# Run the automated installer
chmod +x install_dependencies_macos.sh
./install_dependencies_macos.sh
```

### Manual Installation

#### 1. Homebrew
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update Homebrew
brew update
```

#### 2. Rust
```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

#### 3. Python
```bash
# Install Python via Homebrew
brew install python@3.11

# Verify installation
python3 --version
pip3 --version
```

#### 4. Node.js
```bash
# Install Node.js via Homebrew
brew install node

# Verify installation
node --version
npm --version
```

#### 5. Git
```bash
# Install Git (usually pre-installed on macOS)
brew install git

# Verify installation
git --version
```

#### 6. PostgreSQL
```bash
# Install PostgreSQL
brew install postgresql@14

# Start PostgreSQL service
brew services start postgresql@14

# Create database
createuser axionax
createdb axionax_testnet

# Verify installation
psql --version
```

#### 7. Redis
```bash
# Install Redis
brew install redis

# Start Redis service
brew services start redis

# Verify installation
redis-cli --version
```

#### 8. Docker (Optional)
```bash
# Install Docker Desktop from:
# https://docs.docker.com/desktop/install/mac-install/

# Or using Homebrew
brew install --cask docker

# Verify installation
docker --version
docker-compose --version
```

#### 9. Cargo Tools
```bash
# Install cargo tools
cargo install cargo-tarpaulin
cargo install cargo-audit
cargo install cargo-watch

# Update components
rustup component add clippy
rustup component add rustfmt
```

---

## 🐳 Docker-based Development (All Platforms)

For a containerized development environment without installing dependencies:

```bash
# Clone repository
git clone https://github.com/axionaxprotocol/axionax-core.git
cd axionax-core

# Build Docker image
docker build -t axionax-core .

# Run container
docker run -it --rm -p 8545:8545 -p 30303:30303 axionax-core

# Or use Docker Compose
docker-compose up -d
```

### Docker Compose Services
```yaml
# Included services:
- axionax-core    # Blockchain node
- postgres        # Database
- redis           # Cache
- prometheus      # Metrics
```

---

## ✅ Verification Script

After installation, verify all dependencies:

```bash
# Run verification
python scripts/testing/check_repo_health.py

# Or use readiness checker
python scripts/testing/testnet_readiness_checker.py
```

### Expected Output
```
✅ Rust: 1.75.0+
✅ Python: 3.10.0+
✅ Node.js: 18.0.0+
✅ Git: 2.30.0+
✅ PostgreSQL: 14.0+
✅ Redis: 6.0+
✅ Docker: 20.0+ (optional)
```

---

## 🔧 Python Dependencies

### Core Dependencies

```bash
# Install Python packages
pip install -r requirements.txt

# Or manually:
pip install torch>=2.0.0              # PyTorch for ML
pip install transformers>=4.30.0      # Hugging Face
pip install numpy>=1.24.0             # Numerical computing
pip install pandas>=2.0.0             # Data processing
pip install web3>=6.0.0               # Ethereum integration
pip install psycopg2-binary>=2.9.0    # PostgreSQL driver
pip install redis>=4.5.0              # Redis client
pip install aiohttp>=3.8.0            # Async HTTP
pip install pydantic>=2.0.0           # Data validation
pip install pytest>=7.4.0             # Testing
```

### DeAI-specific Dependencies

```bash
cd deai
pip install -r requirements.txt

# Or manually:
pip install torch torchvision torchaudio  # Deep learning
pip install scikit-learn>=1.3.0           # ML algorithms
pip install nltk>=3.8.0                   # NLP
pip install opencv-python>=4.8.0          # Computer vision
pip install matplotlib>=3.7.0             # Visualization
pip install jupyter>=1.0.0                # Notebooks
```

---

## 🚀 Quick Start After Installation

```bash
# 1. Clone repository
git clone https://github.com/axionaxprotocol/axionax-core.git
cd axionax-core

# 2. Build Rust components
cargo build --release

# 3. Setup Python environment
cd deai
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cd ..

# 4. Configure environment
cp .env.example .env
# Edit .env with your settings

# 5. Initialize database
psql -U postgres -c "CREATE DATABASE axionax_testnet;"
psql -U postgres -d axionax_testnet -f scripts/init_db.sql

# 6. Run tests
cargo test
python -m pytest deai/tests/

# 7. Start node
cargo run --release
```

---

## 🆘 Troubleshooting

### Rust Compilation Errors

**Problem:** `error: linker 'cc' not found`

**Solution:**
```bash
# Linux
sudo apt install build-essential

# macOS
xcode-select --install
```

---

### Python Import Errors

**Problem:** `ModuleNotFoundError: No module named 'torch'`

**Solution:**
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # or venv\Scripts\activate

# Reinstall dependencies
pip install -r requirements.txt

# For CUDA support:
pip install torch --index-url https://download.pytorch.org/whl/cu118
```

---

### PostgreSQL Connection Errors

**Problem:** `psql: error: connection to server failed`

**Solution:**
```bash
# Linux
sudo systemctl start postgresql
sudo systemctl status postgresql

# macOS
brew services start postgresql@14
brew services list

# Windows
net start postgresql-x64-14
```

---

### Redis Connection Errors

**Problem:** `Could not connect to Redis at 127.0.0.1:6379`

**Solution:**
```bash
# Linux
sudo systemctl start redis-server
redis-cli ping  # Should return PONG

# macOS
brew services start redis

# Windows (WSL)
wsl sudo service redis-server start
```

---

## 📚 Additional Resources

- [Rust Documentation](https://doc.rust-lang.org/)
- [Python Official Docs](https://docs.python.org/3/)
- [Node.js Documentation](https://nodejs.org/docs/)
- [PostgreSQL Manual](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Documentation](https://docs.docker.com/)

---

## 🔗 Related Documentation

- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [DEVELOPMENT_SUMMARY.md](DEVELOPMENT_SUMMARY.md) - Development overview
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions

---

## 💬 Support

Need help? 
- Check [GitHub Issues](https://github.com/axionaxprotocol/axionax-core/issues)
- Join our [Discord](https://discord.gg/axionax)
- Read [Documentation](https://docs.axionax.org)
