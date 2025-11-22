# 🚀 Quick Start Guide - axionax-core

## Overview

**axionax-core** เป็น blockchain protocol core ที่เขียนด้วย Rust พร้อมระบบ DeAI (Decentralized AI) ที่เขียนด้วย Python

**Repository:** https://github.com/axionaxprotocol/axionax-core

---

## 📋 Prerequisites

```bash
# Required
- Rust 1.70+ (with cargo)
- Python 3.10+
- Git

# Optional
- Docker (for containerized development)
- PostgreSQL (for local database)
```

---

## 🔧 Installation

### 1. Clone Repository

```bash
git clone https://github.com/axionaxprotocol/axionax-core.git
cd axionax-core
```

### 2. Rust Setup

```bash
# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Update Rust to latest
rustup update

# Verify installation
rustc --version
cargo --version

# Build the project
cargo build

# Build optimized release
cargo build --release
```

### 3. Python DeAI Setup

```bash
# Navigate to DeAI directory
cd deai

# Create virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# On Windows
venv\Scripts\activate
# On Linux/Mac
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import torch; print(torch.__version__)"
```

---

## 🏃 Running the Project

### Start Blockchain Node

```bash
# Development mode with debug logs
cargo run

# Production mode
cargo run --release

# With custom config
cargo run -- --config config/custom.toml

# Run specific validator
cargo run -- --validator --key-path keys/validator.key
```

### Start DeAI System

```bash
cd deai

# Activate virtual environment first
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Run DeAI node
python main.py

# Run with specific config
python main.py --config config/deai.yaml

# Run training
python train.py --model gpt --epochs 100
```

---

## ✅ Testing

### Rust Tests

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_consensus

# Run with output
cargo test -- --nocapture

# Run integration tests only
cargo test --test integration_test

# Run with coverage (requires cargo-tarpaulin)
cargo install cargo-tarpaulin
cargo tarpaulin --out Html
```

### Python Tests

```bash
cd deai

# Run all tests
python -m pytest

# Run with verbose output
python -m pytest -v

# Run specific test file
python -m pytest tests/test_model.py

# Run with coverage
python -m pytest --cov=. --cov-report=html

# Run integration tests
python -m pytest tests/integration/
```

---

## 🏗️ Project Structure

```
axionax-core/
├── src/                        # Rust source code
│   ├── consensus/              # Consensus mechanism (PoPC)
│   ├── network/                # P2P networking
│   ├── storage/                # State & block storage
│   ├── vm/                     # Smart contract VM
│   ├── api/                    # RPC/API endpoints
│   └── lib.rs                  # Main library entry
│
├── deai/                       # Python DeAI system
│   ├── models/                 # AI models
│   ├── training/               # Training scripts
│   ├── inference/              # Inference engine
│   ├── distributed/            # Distributed computing
│   └── main.py                 # Entry point
│
├── tests/                      # Integration tests
├── benches/                    # Performance benchmarks
├── config/                     # Configuration files
├── Cargo.toml                  # Rust dependencies
└── README.md                   # Main documentation
```

---

## 🔨 Common Development Tasks

### Build & Check

```bash
# Fast compile check (no binary output)
cargo check

# Check with all features
cargo check --all-features

# Format code
cargo fmt

# Lint code
cargo clippy

# Fix clippy warnings automatically
cargo clippy --fix
```

### Add New Feature

```bash
# 1. Create feature branch
git checkout -b feature/new-consensus

# 2. Make changes in src/
# ... edit files ...

# 3. Add tests
# ... create tests ...

# 4. Test your changes
cargo test
cargo clippy

# 5. Commit (mention local dev only)
git add .
git commit -m "feat: add new consensus mechanism [Local dev]"

# 6. Push to GitHub
git push origin feature/new-consensus
```

### Benchmarking

```bash
# Run all benchmarks
cargo bench

# Run specific benchmark
cargo bench consensus

# Compare with baseline
cargo bench --bench consensus_bench -- --save-baseline main
```

### Documentation

```bash
# Generate and open documentation
cargo doc --open

# Include private items
cargo doc --document-private-items --open
```

---

## 🐛 Debugging

### Enable Debug Logs

```bash
# Set log level
export RUST_LOG=debug
cargo run

# Specific module logs
export RUST_LOG=axionax_core::consensus=trace
cargo run

# Log to file
cargo run 2> debug.log
```

### Using Debugger

```bash
# Install LLDB/GDB
# VS Code: Install "CodeLLDB" extension

# Run with debugger
rust-lldb target/debug/axionax-core
# or
rust-gdb target/debug/axionax-core
```

### Performance Profiling

```bash
# Install flamegraph
cargo install flamegraph

# Generate flamegraph
cargo flamegraph

# Profile with perf (Linux)
perf record --call-graph=dwarf cargo run
perf report
```

---

## 🌐 API & RPC

### Local RPC Endpoints

```bash
# Default endpoint
http://localhost:8545

# Test RPC connection
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Common RPC Methods

```bash
# Get block number
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Get account balance
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x...","latest"],"id":1}'

# Send transaction
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0x..."],"id":1}'
```

---

## 🔄 Integration with Other Repos

### With axionax-sdk-ts

```bash
# The SDK connects to your local node
# Make sure core node is running on http://localhost:8545

# In axionax-sdk-ts:
# import { AxionaxClient } from '@axionax/sdk'
# const client = new AxionaxClient('http://localhost:8545')
```

### With axionax-deploy

```bash
# Deploy scripts use the built binaries
cd ../axionax-deploy
npm run deploy:local

# This will start your axionax-core node
```

### With axionax-devtools

```bash
# Run integration tests
cd ../axionax-devtools
python scripts/testing/test_repo_integration.py

# This tests axionax-core along with other repos
```

---

## 📝 Configuration

### Main Config File: `config/node.toml`

```toml
[network]
listen_addr = "0.0.0.0:30333"
bootnodes = []

[consensus]
algorithm = "popc"
block_time = 6

[storage]
data_dir = "data/"
db_type = "rocksdb"

[api]
http_addr = "127.0.0.1:8545"
ws_addr = "127.0.0.1:8546"
```

### DeAI Config: `deai/config/deai.yaml`

```yaml
model:
  type: "transformer"
  layers: 12
  hidden_size: 768

training:
  batch_size: 32
  learning_rate: 0.0001
  epochs: 100

distributed:
  enabled: true
  workers: 4
```

---

## 🚨 Troubleshooting

### Build Errors

```bash
# Clean build artifacts
cargo clean

# Update dependencies
cargo update

# Rebuild from scratch
cargo clean && cargo build
```

### Runtime Errors

```bash
# Check logs
tail -f data/logs/node.log

# Increase verbosity
RUST_LOG=trace cargo run

# Reset database
rm -rf data/db && cargo run
```

### Python Environment Issues

```bash
# Recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## 📚 Additional Resources

- **Main Documentation:** https://axionaxprotocol.github.io/axionax-docs/
- **API Reference:** https://docs.axionax.org/api
- **Architecture Guide:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Contributing Guide:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issue Tracker:** https://github.com/axionaxprotocol/axionax-core/issues

---

## 🤝 Getting Help

- **Issues:** Report bugs on [GitHub Issues](https://github.com/axionaxprotocol/axionax-core/issues)
- **Documentation:** Check [axionax-docs](https://github.com/axionaxprotocol/axionax-docs)
- **Development Tools:** Use [axionax-devtools](https://github.com/axionaxprotocol/axionax-devtools)

---

## 📄 License

AGPLv3 - See [LICENSE](LICENSE) file for details

---

<p align="center">
  <sub>Built with ❤️ by the axionax protocol Team</sub>
</p>
