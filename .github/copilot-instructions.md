# Axionax Core Universe - AI Coding Agent Instructions

**Project:** Axionax Protocol Layer-1 Blockchain  
**Architecture:** Monorepo with Rust core, Python ML, TypeScript SDK, DevOps tooling  
**Status:** Pre-testnet (v1.8.0) - targeting Q1 2026 public launch

---

## 🏗️ Monorepo Structure

This is a **monorepo** with three major components:

```
axionax-core-universe/
├── core/              # Blockchain protocol (Rust + Python)
├── ops/deploy/        # Deployment infrastructure (Docker, K8s)
└── tools/devtools/    # Development utilities (Python, Bash)
```

**Key principle:** Each subdirectory has its own `.github/copilot-instructions.md` with component-specific guidance. This file covers cross-cutting concerns.

---

## 🎯 Architecture Overview

### Multi-Language Design Philosophy

**Why multiple languages:**
- **Rust (80%):** Performance-critical core - consensus, networking, state management
- **Python (10%):** ML-powered DeAI layer - Auto-Selection Router, fraud detection
- **TypeScript (10%):** Client SDKs and web interfaces

**Integration point:** PyO3 Rust↔Python bridge at `core/bridge/rust-python/`

### Core Components Flow

```
┌──────────────┐
│  RPC Layer   │ ← JSON-RPC 2.0 (Ethereum-compatible)
│  (Port 8545) │
└──────┬───────┘
       │
┌──────▼──────────────────────────┐
│  Consensus Engine (PoPC)        │ ← Proof of Probabilistic Checking
│  - VRF-based sampling           │
│  - Challenge generation         │
└──────┬──────────────────────────┘
       │
┌──────▼──────────────────────────┐
│  State Management (RocksDB)     │ ← Merkle Patricia Trie
│  - Block storage                │
│  - Transaction pool (mempool)   │
└──────┬──────────────────────────┘
       │
┌──────▼──────────────────────────┐
│  Network Layer (libp2p)         │ ← P2P gossip protocol
│  - Block propagation            │
│  - Peer discovery               │
└─────────────────────────────────┘
```

**DeAI Integration:** Python components at `core/deai/` call Rust functions via PyO3 bridge.

### PoPC Consensus Algorithm Deep Dive

**Proof of Probabilistic Checking (PoPC)** - ความแตกต่างจากแบบอื่น:

```
Traditional PoW/PoS:          PoPC:
┌──────────────┐              ┌──────────────┐
│ Verify ALL   │              │ Sample SOME  │
│ transactions │              │ strategically│
│ O(n) cost    │              │ O(s) cost    │
└──────────────┘              └──────────────┘
   ↓ Expensive                   ↓ Efficient
   High latency                  Low latency
```

**Core formula (MUST be identical in Rust and Python):**
```
P(detect fraud) = 1 - (1 - f)^s

where:
  f = fraud rate (0-1)
  s = sample size
  
Example: f=0.1, s=100 → P=0.99997 (99.997% detection)
```

**Key innovations:**
1. **VRF-based sampling**: Verifiable Random Function ensures unpredictable challenge selection
2. **k-block delay**: Challenges generated k blocks after submission (prevents gaming)
3. **Stratified sampling**: Ensures coverage across all data segments
4. **Adaptive sizing**: Sample size adjusts based on network fraud rate history

**Implementation locations:**
- Rust: `core/core/consensus/src/lib.rs::fraud_detection_probability()`
- Python: `core/deai/fraud_detection.py::fraud_detection_probability()`
- Tests: `core/core/consensus/src/lib.rs` (unit) + `core/tests/integration_simple.py` (integration)

---

## 🦀 Rust Development Standards

### Error Handling (CRITICAL)

**BANNED patterns:**
```rust
// ❌ NEVER do this in production code
result.unwrap();
result.expect("message");
```

**Required patterns:**
```rust
// ✅ Application code (core/node, core/rpc)
use anyhow::{Context, Result};

pub fn process_block(block: Block) -> Result<()> {
    validate_block(&block)
        .context("Failed to validate block")?;
    Ok(())
}

// ✅ Library code (core/consensus, core/crypto)
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConsensusError {
    #[error("Invalid VRF proof")]
    InvalidProof,
}
```

**Exception:** `.unwrap()` is acceptable in:
- Test code (`#[cfg(test)]`)
- Benchmark code (`benches/`)
- Example code (`examples/`)
- After explicit validation checks (document with comment)

### Async Patterns

**Tokio runtime conventions:**
```rust
// ✅ Shared state pattern
use tokio::sync::RwLock;
use std::sync::Arc;

let state = Arc::new(RwLock::new(StateDB::new()?));

// Pass Arc<RwLock<T>> between components
let network = NetworkManager::new(Arc::clone(&state)).await?;
```

**Key files using this pattern:**
- `core/core/node/src/lib.rs` - Main node orchestration
- `core/bridge/rust-python/src/lib.rs` - PyO3 async bridge
- `core/core/network/src/manager.rs` - P2P network manager

### Performance-Critical Code

**Hash function selection (see `core/core/crypto/`):**
```rust
// ✅ Use Blake2s-256 for high-throughput operations
use crypto::hash::blake2s_256;
let hash = blake2s_256(&data);  // 2-3x faster than SHA3

// ✅ Use SHA3-256 only when standards compliance required
use crypto::hash::sha3_256;
let hash = sha3_256(&vrf_input);  // For VRF operations
```

**Why:** Benchmarks show Blake2s is 2-3x faster (see `core/benches/crypto_bench.rs`).

### Common Code Patterns (ตัวอย่างที่พบบ่อย)

#### 1. Adding a New RPC Method (เพิ่ม RPC method ใหม่)

```rust
// File: core/core/rpc/src/lib.rs

// ✅ Step 1: Add method to RpcServer impl
impl RpcServer {
    pub async fn eth_get_balance(
        &self,
        address: String,
        block_number: Option<String>,
    ) -> Result<String, RpcError> {
        // Validate address
        if !is_valid_address(&address) {
            return Err(RpcError::InvalidParams("Invalid address format".into()));
        }
        
        // Query state database
        let balance = self.state
            .read().await
            .get_balance(&address)
            .context("Failed to query balance")?;
        
        // Return hex-encoded value (Ethereum compatibility)
        Ok(format!("0x{:x}", balance))
    }
}

// ✅ Step 2: Register in router (same file)
pub fn create_router() -> Router {
    Router::new()
        .route("/", post(handle_rpc))
        .route("/health", get(health_check))
        // Add your method to the handler
}

// ✅ Step 3: Add test
#[cfg(test)]
mod tests {
    #[tokio::test]
    async fn test_get_balance() {
        let server = RpcServer::new_test().await;
        let result = server.eth_get_balance(
            "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb".into(),
            None
        ).await;
        assert!(result.is_ok());
    }
}
```

#### 2. Modifying Consensus Logic (แก้ไข consensus)

```rust
// File: core/core/consensus/src/lib.rs

impl ConsensusEngine {
    // ✅ ALWAYS add comprehensive comments for consensus changes
    /// Generate PoPC challenge with enhanced security
    /// 
    /// Changes from v1.7:
    /// - Added k-block delay (k=10) to prevent predictability
    /// - Increased minimum sample size from 100 to 1000
    /// - Added stratified sampling for better coverage
    pub fn generate_challenge_v2(
        &self,
        job_id: String,
        output_size: usize,
        vrf_seed: [u8; 32],
    ) -> Result<Challenge, ConsensusError> {
        // Validate inputs
        if output_size < MIN_OUTPUT_SIZE {
            return Err(ConsensusError::InvalidOutputSize);
        }
        
        // Calculate sample size (adaptive based on history)
        let sample_size = self.calculate_adaptive_sample_size()?;
        
        // Generate VRF proof (delayed by k blocks)
        let vrf_proof = self.generate_delayed_vrf(vrf_seed, DELAY_BLOCKS)?;
        
        // Create stratified sample indices
        let indices = self.stratified_sample(output_size, sample_size, &vrf_proof)?;
        
        Ok(Challenge {
            job_id,
            sample_indices: indices,
            vrf_proof,
            timestamp: current_timestamp(),
        })
    }
}

// ✅ MUST add corresponding test
#[cfg(test)]
mod tests {
    #[test]
    fn test_challenge_generation_v2() {
        let engine = ConsensusEngine::new(ConsensusConfig::default());
        let challenge = engine.generate_challenge_v2(
            "job_123".into(),
            10000,
            [1u8; 32]
        );
        assert!(challenge.is_ok());
        assert!(challenge.unwrap().sample_indices.len() >= 1000);
    }
}
```

#### 3. Adding State Database Fields (เพิ่ม field ใน state)

```rust
// File: core/core/state/src/lib.rs

use rocksdb::{DB, ColumnFamily};

// ✅ Define column family constants
const CF_BLOCKS: &str = "blocks";
const CF_TRANSACTIONS: &str = "transactions";
const CF_BALANCES: &str = "balances";  // New column family

impl StateDB {
    pub fn new(path: &str) -> Result<Self> {
        let mut opts = rocksdb::Options::default();
        opts.create_if_missing(true);
        opts.create_missing_column_families(true);
        
        // ✅ Register all column families
        let db = DB::open_cf(
            &opts,
            path,
            &[CF_BLOCKS, CF_TRANSACTIONS, CF_BALANCES],
        )?;
        
        Ok(StateDB { db: Arc::new(db) })
    }
    
    // ✅ Add getter/setter for new field
    pub fn get_balance(&self, address: &str) -> Result<u128> {
        let cf = self.db.cf_handle(CF_BALANCES)
            .ok_or(StateError::ColumnFamilyNotFound)?;
        
        let key = address.as_bytes();
        match self.db.get_cf(cf, key)? {
            Some(bytes) => {
                let balance = u128::from_be_bytes(
                    bytes.try_into()
                        .map_err(|_| StateError::InvalidBalance)?
                );
                Ok(balance)
            },
            None => Ok(0), // Default balance
        }
    }
    
    pub fn set_balance(&self, address: &str, balance: u128) -> Result<()> {
        let cf = self.db.cf_handle(CF_BALANCES)
            .ok_or(StateError::ColumnFamilyNotFound)?;
        
        let key = address.as_bytes();
        let value = balance.to_be_bytes();
        
        self.db.put_cf(cf, key, value)?;
        Ok(())
    }
}
```

#### 4. Network Message Handling (จัดการ network message)

```rust
// File: core/core/network/src/manager.rs

use libp2p::gossipsub::Event as GossipsubEvent;

// ✅ Pattern for handling network messages
impl NetworkManager {
    pub async fn handle_gossipsub_event(
        &mut self,
        event: GossipsubEvent,
    ) -> Result<()> {
        match event {
            GossipsubEvent::Message { message, .. } => {
                // Deserialize message
                let network_msg = NetworkMessage::from_bytes(&message.data)
                    .context("Failed to decode network message")?;
                
                // Route based on message type
                match network_msg {
                    NetworkMessage::Block(block) => {
                        self.handle_block(block).await?;
                    },
                    NetworkMessage::Transaction(tx) => {
                        self.handle_transaction(tx).await?;
                    },
                    NetworkMessage::NewBlock(header) => {
                        self.request_full_block(header).await?;
                    },
                }
            },
            GossipsubEvent::Subscribed { peer_id, topic } => {
                tracing::info!("Peer {:?} subscribed to {:?}", peer_id, topic);
            },
            _ => {}
        }
        Ok(())
    }
}
```

---

## 🐍 Python/DeAI Standards

### Mathematical Precision (PoPC Consensus)

**Critical formula implementation** (in `core/deai/fraud_detection.py`):
```python
def fraud_detection_probability(fraud_rate: float, sample_size: int) -> float:
    """
    PoPC formula: P_detect = 1 - (1 - f)^s
    where f = fraud rate, s = sample size
    
    CRITICAL: This must match Rust implementation in core/consensus
    """
    return 1.0 - (1.0 - fraud_rate) ** sample_size
```

**Testing requirement:** Any change to this logic MUST have corresponding test in both Python and Rust.

### PyO3 Bridge Usage

**Calling Rust from Python:**
```python
# Import compiled Rust module (built via maturin)
import axionax_python as axx

# Use Rust types wrapped in Python
vrf = axx.PyVRF()
proof, output = vrf.prove(b"seed_data")

# Bridge maintains Tokio runtime internally
# See: core/bridge/rust-python/src/lib.rs
```

**Building the bridge:**
```bash
cd core/bridge/rust-python
./build.sh  # Compiles and copies to core/deai/lib/
```

### Type Hints (Mandatory)

```python
# ✅ All function signatures must be typed
from typing import List, Dict, Optional, Tuple

def analyze_worker_history(
    worker_addr: str,
    proofs: List[ProofData]
) -> Tuple[float, Dict[str, float]]:
    """Analyze worker proof history for fraud indicators."""
    ...
```

### PyO3 Bridge: Advanced Patterns (คู่มือการใช้งาน)

#### Building and Installing the Bridge

```bash
# Development workflow
cd core/bridge/rust-python

# Option 1: Quick build (production)
./build.sh

# Option 2: Development build with hot reload
maturin develop

# Option 3: Release build for distribution
maturin build --release

# Verify installation
python -c "import axionax_python; print(axionax_python.__version__)"
```

#### Rust Side: Exposing Functions to Python

```rust
// File: core/bridge/rust-python/src/lib.rs

use pyo3::prelude::*;
use pyo3::exceptions::PyRuntimeError;

// ✅ Pattern 1: Simple function binding
#[pyfunction]
fn calculate_hash(data: &[u8]) -> PyResult<String> {
    let hash = blake2s_256(data);
    Ok(hex::encode(hash))
}

// ✅ Pattern 2: Class with state (using Tokio runtime)
#[pyclass]
pub struct PyConsensusEngine {
    runtime: tokio::runtime::Runtime,
    engine: Arc<RwLock<ConsensusEngine>>,
}

#[pymethods]
impl PyConsensusEngine {
    #[new]
    fn new() -> PyResult<Self> {
        let runtime = tokio::runtime::Runtime::new()
            .map_err(|e| PyRuntimeError::new_err(format!("Tokio error: {}", e)))?;
        
        let config = ConsensusConfig::default();
        let engine = Arc::new(RwLock::new(ConsensusEngine::new(config)));
        
        Ok(PyConsensusEngine { runtime, engine })
    }
    
    // ✅ Async method exposed to Python
    fn generate_challenge(
        &self,
        job_id: String,
        output_size: usize,
    ) -> PyResult<PyChallenge> {
        // Run async code in Tokio runtime
        let engine = Arc::clone(&self.engine);
        let result = self.runtime.block_on(async move {
            let engine_guard = engine.read().await;
            engine_guard.generate_challenge(job_id, output_size, [0u8; 32])
        });
        
        result
            .map(|c| PyChallenge::from(c))
            .map_err(|e| PyRuntimeError::new_err(format!("Consensus error: {}", e)))
    }
}

// ✅ Pattern 3: Module registration
#[pymodule]
fn axionax_python(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(calculate_hash, m)?)?;
    m.add_class::<PyConsensusEngine>()?;
    m.add_class::<PyVRF>()?;
    m.add_class::<PyBlockchain>()?;
    Ok(())
}
```

#### Python Side: Using Rust Components

```python
# File: core/deai/asr.py

import axionax_python as axx
import numpy as np
from typing import List, Dict

class AutoSelectionRouter:
    """ML-powered worker selection using Rust consensus engine."""
    
    def __init__(self):
        # Initialize Rust components
        self.consensus = axx.PyConsensusEngine()
        self.vrf = axx.PyVRF()
        
    def select_workers(
        self,
        job_id: str,
        num_workers: int,
        available_workers: List[str]
    ) -> List[str]:
        """Select workers using VRF for fairness."""
        
        # Use Rust VRF for random selection
        seed = job_id.encode('utf-8')
        proof, output = self.vrf.prove(seed)
        
        # Convert VRF output to worker indices
        indices = self._vrf_to_indices(
            output,
            num_workers,
            len(available_workers)
        )
        
        return [available_workers[i] for i in indices]
    
    def verify_worker_selection(
        self,
        job_id: str,
        selected_workers: List[str],
        proof: bytes
    ) -> bool:
        """Verify worker selection was done fairly."""
        seed = job_id.encode('utf-8')
        return self.vrf.verify(seed, proof, output)
```

#### Testing PyO3 Bridge

```python
# File: core/tests/integration_simple.py

import pytest
import axionax_python as axx

def test_rust_python_bridge_basic():
    """Test basic PyO3 bridge functionality."""
    # VRF operations
    vrf = axx.PyVRF()
    proof, output = vrf.prove(b"test_input")
    
    assert vrf.verify(b"test_input", proof, output)
    assert len(output) == 32  # VRF output is 32 bytes

def test_consensus_bridge():
    """Test consensus engine through bridge."""
    engine = axx.PyConsensusEngine()
    
    # Generate challenge
    challenge = engine.generate_challenge("job_123", 10000)
    
    assert challenge.job_id == "job_123"
    assert len(challenge.sample_indices) >= 100
    
    # Verify fraud detection probability matches
    rust_prob = axx.PyConsensusEngine.fraud_probability(0.1, 100)
    python_prob = 1.0 - (1.0 - 0.1) ** 100
    
    assert abs(rust_prob - python_prob) < 1e-10  # Must be identical

def test_blockchain_bridge():
    """Test blockchain operations through bridge."""
    blockchain = axx.PyBlockchain()
    
    # Query blockchain state
    height = blockchain.latest_block_number()
    assert height >= 0
    
    block = blockchain.get_block(0)  # Genesis block
    assert block is not None

@pytest.mark.benchmark
def test_bridge_performance():
    """Benchmark bridge overhead."""
    import time
    
    vrf = axx.PyVRF()
    
    # Measure Rust performance through bridge
    start = time.perf_counter()
    for i in range(1000):
        vrf.prove(f"input_{i}".encode())
    rust_time = time.perf_counter() - start
    
    print(f"1000 VRF operations through bridge: {rust_time:.3f}s")
    print(f"Average per operation: {rust_time/1000*1000:.3f}ms")
    
    # Bridge overhead should be < 10%
    assert rust_time < 1.0  # 1000 ops in < 1 second
```

#### Common PyO3 Bridge Issues

**Problem 1: "Module not found"**
```bash
# Solution: Rebuild and check Python path
cd core/bridge/rust-python
./build.sh
python -c "import sys; print(sys.path)"
# Library should be in core/deai/lib/
```

**Problem 2: "Tokio runtime error"**
```rust
// ✅ Correct: Create ONE runtime per Python object
#[pyclass]
struct MyClass {
    runtime: tokio::runtime::Runtime,  // Own runtime
}

// ❌ Wrong: Sharing runtime across Python objects
static RUNTIME: OnceCell<Runtime> = OnceCell::new();  // Don't do this
```

**Problem 3: "Type conversion error"**
```python
# ✅ Correct: Use proper types
vrf = axx.PyVRF()
proof, output = vrf.prove(b"binary_data")  # bytes, not str

# ❌ Wrong: Passing wrong types
proof, output = vrf.prove("string_data")  # Will fail
```

---

## 🏃 Build & Test Workflows

### Quick Commands (from monorepo root)

```bash
# Build everything
cargo build --workspace --release

# Run all tests (Rust + Python)
cd core && make check

# Individual test suites
cargo test -p consensus      # Consensus module tests
cargo test -p blockchain     # Blockchain tests
pytest core/tests/           # Python integration tests

# Linting
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --all --check
```

### CI/CD Expectations

**Pre-commit checklist** (automated in future):
1. All Rust tests pass: `cargo test --workspace`
2. No clippy warnings: `cargo clippy -- -D warnings`
3. Code formatted: `cargo fmt --all`
4. Python tests pass: `pytest core/tests/`
5. No `.unwrap()` in production code (checked by grep)

### Configuration Management

**Three environments:**
- **Dev:** `core/core/node/src/lib.rs` → `NodeConfig::dev()`
- **Testnet:** Chain ID `86137`, public RPC planned Q1 2026
- **Mainnet:** Chain ID `86150` (reserved, not launched)

**Configuration loading priority:**
1. CLI arguments (`--config testnet`)
2. Environment variables (`AXIONAX_RPC_ADDR=0.0.0.0:8545`)
3. Config files (`config/testnet.toml`)
4. Hardcoded defaults

---

## 🔒 Security Requirements

### Pre-Production Checklist

**Before ANY testnet deployment:**
- [ ] Professional security audit completed (see `core/SECURITY_AUDIT.md`)
- [ ] No hardcoded secrets (checked via `git grep -n "sk_" "pk_"`)
- [ ] Rate limiting enabled on RPC (default: 100 req/min)
- [ ] CORS properly configured (whitelist only)
- [ ] TLS/SSL certificates installed
- [ ] Snyk security scan clean

**Known security status (Nov 2025):**
- ✅ No critical vulnerabilities in dependencies
- ✅ Argon2id password hashing (OWASP recommended)
- ✅ Rate limiting middleware implemented
- ⚠️ Professional audit PENDING (Trail of Bits/OpenZeppelin recommended)

### Cryptography Standards

**Use established implementations only:**
```rust
// ✅ Use these crates (defined in workspace Cargo.toml)
use ed25519_dalek::{Keypair, Signature};  // Digital signatures
use sha3::{Sha3_256, Digest};             // Hashing
use blake2::{Blake2s256, Blake2b512};     // Fast hashing
use rand::rngs::OsRng;                    // Secure randomness

// ❌ NEVER roll your own crypto
```

---

## 🚀 Deployment Conventions

### Docker Patterns (ops/deploy/)

**Service health checks (required):**
```yaml
# All services must define health checks
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8545/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**Port conventions:**
- `8545`: RPC HTTP endpoint (Ethereum standard)
- `8546`: WebSocket endpoint
- `30303`: P2P network port
- `9090`: Prometheus metrics
- `3030`: Grafana dashboard

### Infrastructure as Code

**Terraform/Ansible usage:**
- All infrastructure changes must be idempotent
- Use `terraform plan` before `apply`
- Store state in remote backend (S3/GCS)
- Never commit `.tfstate` files

**See:** `ops/deploy/setup_validator.sh` for production setup example.

---

## 📊 Performance Targets

**Current benchmarks** (as of v1.8.0):

| Metric              | Target      | Current      | Test File                  |
|---------------------|-------------|--------------|----------------------------|
| Transaction TPS     | 50,000      | 45,000+      | `tools/devtools/tests/`    |
| Block time          | 2s          | ~2s          | `core/consensus/`          |
| Finality            | <0.5s       | ~0.5s        | Integration tests          |
| VRF ops/sec         | 25,000      | 22,817       | `core/benches/crypto_bench.rs` |
| Memory (idle node)  | <100MB      | 45MB         | `docker stats`             |

**How to benchmark:**
```bash
# Crypto benchmarks
cd core && cargo bench

# Load testing (Python)
cd tools/devtools && python tests/load_test.py --tps 50000
```

### Performance Optimization Checklist (เช็คลิสต์เพิ่มประสิทธิภาพ)

#### 🔥 Hot Path Optimizations

1. **Hash Function Selection** (เลือก hash function ที่เหมาะสม)
```rust
// ✅ Use Blake2s for high-frequency operations
use crypto::hash::blake2s_256;

// Transaction hashing (called millions of times)
let tx_hash = blake2s_256(&tx_bytes);  // 2-3x faster

// Block header hashing
let block_hash = blake2s_256(&header_bytes);

// ⚠️ Use SHA3 only when required by spec
use crypto::hash::sha3_256;
let vrf_input = sha3_256(&challenge_bytes);  // VRF standard
```

2. **Avoid Unnecessary Clones** (หลีกเลี่ยง .clone() ที่ไม่จำเป็น)
```rust
// ❌ Bad: Unnecessary clone
fn process_block(block: Block) {
    let block_clone = block.clone();  // Expensive!
    validate_block(&block_clone);
}

// ✅ Good: Use references
fn process_block(block: &Block) {
    validate_block(block);  // Zero-cost
}

// ✅ Good: Use Arc for shared ownership
let block = Arc::new(block);
let block_ref = Arc::clone(&block);  // Cheap reference count increment
```

3. **Batch Database Operations** (รวม database operations)
```rust
// ❌ Bad: Multiple individual writes
for tx in transactions {
    state.put_transaction(&tx)?;  // Disk I/O each time
}

// ✅ Good: Batch write
let mut batch = state.new_batch();
for tx in transactions {
    batch.put_transaction(&tx);
}
state.write_batch(batch)?;  // Single disk I/O
```

4. **Use BTreeMap for Sorted Data** (ใช้ BTreeMap สำหรับข้อมูลที่เรียงลำดับ)
```rust
// ✅ Transaction pool with nonce ordering
use std::collections::BTreeMap;

pub struct TransactionPool {
    // Key: (address, nonce) for automatic sorting
    transactions: BTreeMap<(Address, u64), Transaction>,
}

impl TransactionPool {
    pub fn get_next_transactions(&self, limit: usize) -> Vec<Transaction> {
        self.transactions.values()
            .take(limit)
            .cloned()
            .collect()
    }
}
```

5. **Lazy Evaluation** (ประเมินค่าแบบ lazy)
```rust
// ✅ Use lazy_static for expensive initialization
use lazy_static::lazy_static;

lazy_static! {
    static ref GENESIS_BLOCK: Block = {
        // Expensive computation only done once
        let mut block = Block::new();
        block.compute_merkle_root();
        block
    };
}
```

#### 🎯 Profiling and Debugging Tips

**CPU Profiling (หา bottleneck)**
```bash
# Install tools
cargo install flamegraph
cargo install cargo-instruments  # macOS only

# Generate flamegraph
sudo cargo flamegraph --bin node -- --config testnet
# Opens flamegraph.svg in browser

# On macOS with Instruments
cargo instruments --bin node --template time
```

**Memory Profiling (ตรวจสอบ memory)**
```bash
# Install valgrind
sudo apt-get install valgrind

# Check for memory leaks
valgrind --leak-check=full --show-leak-kinds=all \
  ./target/debug/node --config testnet

# Heap profiling
valgrind --tool=massif ./target/debug/node
ms_print massif.out.<PID>
```

**Debug Logging Strategy (การใช้ log อย่างมีประสิทธิภาพ)**
```rust
use tracing::{debug, info, warn, error, instrument};

// ✅ Use appropriate log levels
#[instrument(skip(data))]  // Don't log large data
pub async fn process_transaction(tx_hash: String, data: Vec<u8>) -> Result<()> {
    info!("Processing transaction: {}", tx_hash);  // Production
    debug!("Transaction size: {} bytes", data.len());  // Dev only
    
    if let Err(e) = validate_transaction(&data) {
        error!("Validation failed: {:?}", e);  // Always log errors
        return Err(e);
    }
    
    warn_if_slow!("Transaction processing", 100, {  // Warn if > 100ms
        // Processing code
    });
    
    Ok(())
}

// Run with specific log levels
// RUST_LOG=info,axionax::consensus=debug cargo run
```

**Benchmark-Driven Development (ใช้ benchmark ขับเคลื่อน)**
```rust
// benches/crypto_bench.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_hash_functions(c: &mut Criterion) {
    let data = vec![0u8; 1024];
    
    // Compare hash functions
    c.bench_function("blake2s_256", |b| {
        b.iter(|| blake2s_256(black_box(&data)))
    });
    
    c.bench_function("sha3_256", |b| {
        b.iter(|| sha3_256(black_box(&data)))
    });
}

criterion_group!(benches, benchmark_hash_functions);
criterion_main!(benches);

// Run and compare
// cargo bench
// Results show Blake2s is 2-3x faster
```

**Assert Performance in Tests (ทดสอบประสิทธิภาพ)**
```rust
#[cfg(test)]
mod tests {
    use std::time::Instant;
    
    #[test]
    fn test_block_validation_performance() {
        let block = create_test_block();
        
        let start = Instant::now();
        let result = validate_block(&block);
        let duration = start.elapsed();
        
        assert!(result.is_ok());
        // Ensure validation takes < 10ms
        assert!(duration.as_millis() < 10,
            "Block validation too slow: {:?}", duration);
    }
}
```

---

## 🧪 Testing Philosophy

### Test Organization

```
core/
├── core/consensus/src/lib.rs     # Unit tests in same file
├── core/consensus/tests/          # Integration tests
├── tests/                         # Python E2E tests
└── benches/                       # Performance benchmarks
```

**Coverage expectations:**
- Core modules: >80% line coverage
- Critical paths (consensus, crypto): >95%
- Current status: 42/42 tests passing (see `core/DEVELOPMENT_SUMMARY.md`)

### Integration Test Pattern

```python
# core/tests/integration_simple.py
def test_rust_python_bridge():
    """Verify PyO3 bridge works correctly."""
    import axionax_python as axx
    
    vrf = axx.PyVRF()
    proof, output = vrf.prove(b"test_input")
    
    # Must verify in both directions
    assert vrf.verify(b"test_input", proof, output)
```

### Advanced Testing Patterns (รูปแบบการทดสอบขั้นสูง)

#### Property-Based Testing (ทดสอบด้วย property)

```rust
// Add to Cargo.toml: proptest = "1.0"
use proptest::prelude::*;

// Test mathematical properties
proptest! {
    #[test]
    fn test_fraud_detection_probability_bounds(
        fraud_rate in 0.0..1.0,
        sample_size in 1usize..10000
    ) {
        let prob = ConsensusEngine::fraud_detection_probability(
            fraud_rate,
            sample_size
        );
        
        // Property: Probability must be between 0 and 1
        prop_assert!(prob >= 0.0 && prob <= 1.0);
        
        // Property: Higher sample size = higher detection probability
        if sample_size > 1 {
            let prob_smaller = ConsensusEngine::fraud_detection_probability(
                fraud_rate,
                sample_size - 1
            );
            prop_assert!(prob >= prob_smaller);
        }
    }
    
    #[test]
    fn test_hash_determinism(data: Vec<u8>) {
        // Property: Hash must be deterministic
        let hash1 = blake2s_256(&data);
        let hash2 = blake2s_256(&data);
        prop_assert_eq!(hash1, hash2);
    }
}
```

#### Fuzzing Tests (ทดสอบด้วย random input)

```rust
// File: fuzz/fuzz_targets/block_parser.rs
#![no_main]
use libfuzzer_sys::fuzz_target;
use blockchain::Block;

fuzz_target!(|data: &[u8]| {
    // Try to parse random data as block
    let _ = Block::from_bytes(data);
    // Should never panic, only return error
});

// Run fuzzer
// cargo install cargo-fuzz
// cargo fuzz run block_parser -- -max_total_time=300
```

#### Integration Test with Real Network

```rust
// tests/network_integration.rs
#[tokio::test]
#[ignore]  // Run only with --ignored flag
async fn test_connect_to_testnet() -> Result<()> {
    // Spin up local node
    let config = NodeConfig {
        chain_id: 86137,
        bootstrap_nodes: vec![
            "/ip4/testnet1.axionax.org/tcp/30303/p2p/...".to_string(),
        ],
        ..Default::default()
    };
    
    let node = AxionaxNode::new(config).await?;
    
    // Wait for peer connection
    tokio::time::sleep(Duration::from_secs(30)).await;
    
    let stats = node.get_stats().await;
    assert!(stats.peer_count > 0, "No peers connected");
    
    // Verify can sync blocks
    let latest_block = node.get_latest_block().await?;
    assert!(latest_block.number > 0);
    
    Ok(())
}
```

#### Snapshot Testing (ทดสอบด้วย snapshot)

```rust
// tests/snapshot_tests.rs
use insta::assert_json_snapshot;

#[test]
fn test_genesis_block_structure() {
    let genesis = Block::genesis();
    
    // Snapshot the JSON structure
    assert_json_snapshot!(genesis, @r###"
    {
      "number": 0,
      "hash": "0x000...000",
      "parent_hash": "0x000...000",
      "timestamp": 0,
      "transactions": []
    }
    "###);
}

// Update snapshots: cargo test -- --nocapture
// Review with: cargo insta review
```

#### Performance Regression Tests

```rust
#[cfg(test)]
mod perf_tests {
    use std::time::Instant;
    
    #[test]
    fn test_no_performance_regression() {
        let baseline_ms = 100;  // From previous version
        
        let start = Instant::now();
        for _ in 0..1000 {
            let _ = process_transaction(&create_test_tx());
        }
        let duration = start.elapsed().as_millis();
        
        // Fail if performance degrades > 20%
        assert!(
            duration < baseline_ms * 120 / 100,
            "Performance regression: {}ms (baseline: {}ms)",
            duration, baseline_ms
        );
    }
}
```

### CI/CD Best Practices (แนวทางปฏิบัติที่ดี)

#### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          components: clippy, rustfmt
          
      - name: Cache cargo
        uses: actions/cache@v3
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
          
      - name: Check formatting
        run: cargo fmt --all -- --check
        
      - name: Run clippy
        run: cargo clippy --all-targets --all-features -- -D warnings
        
      - name: Run tests
        run: cargo test --workspace --all-features
        
      - name: Run benchmarks (sanity check)
        run: cargo bench --no-run
        
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run security audit
        run: |
          cargo install cargo-audit
          cargo audit
          
      - name: Check for unwrap/expect in production
        run: |
          ! grep -rn "\.unwrap()" core/core --include="*.rs" | grep -v "test" | grep -v "example"
          ! grep -rn "\.expect(" core/core --include="*.rs" | grep -v "test" | grep -v "example"
```

#### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Format check
echo "Checking formatting..."
cargo fmt --all -- --check

# Clippy
echo "Running clippy..."
cargo clippy --all-targets -- -D warnings

# Quick tests
echo "Running quick tests..."
cargo test --lib --bins

# Check for forbidden patterns
echo "Checking for .unwrap() in production code..."
if grep -rn "\.unwrap()" core/core --include="*.rs" | grep -v "test" | grep -v "example"; then
    echo "ERROR: Found .unwrap() in production code"
    exit 1
fi

echo "✅ All checks passed!"
```

---

## 🔧 Troubleshooting Common Issues

### Build Failures

**Windows: "bindgen requires libclang"**
```powershell
# Install LLVM (required for libp2p)
# Download: https://github.com/llvm/llvm-project/releases
# Set: LIBCLANG_PATH=C:\Program Files\LLVM\bin
```

**Linux: "cannot find -lssl"**
```bash
sudo apt-get install libssl-dev pkg-config
```

### Runtime Issues

**"Address already in use (os error 98)"**
```bash
# Find and kill process on port 8545
lsof -ti:8545 | xargs kill -9
```

**Python bridge not found**
```bash
# Rebuild PyO3 bridge
cd core/bridge/rust-python
./build.sh
python -c "import axionax_python"  # Should not error
```

### Extended Troubleshooting Guide (คู่มือแก้ปัญหาแบบละเอียด)

#### Build Issues (ปัญหาการ compile)

**Issue: "linker `cc` not found" (Linux)**
```bash
# Install build essentials
sudo apt-get update
sudo apt-get install build-essential gcc g++ make

# For Alpine Linux
apk add gcc musl-dev
```

**Issue: "error: failed to run custom build command for `openssl-sys`"**
```bash
# Ubuntu/Debian
sudo apt-get install libssl-dev pkg-config

# CentOS/RHEL
sudo yum install openssl-devel

# macOS
brew install openssl@3
export OPENSSL_DIR=$(brew --prefix openssl@3)
```

**Issue: "could not find native static library `rocksdb`"**
```bash
# Install RocksDB development files
sudo apt-get install librocksdb-dev

# Or build from source
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
make static_lib
sudo make install
```

**Issue: Windows MSVC linker errors**
```powershell
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/downloads/
# Select "Desktop development with C++"

# Or use Rust with GNU toolchain
rustup default stable-x86_64-pc-windows-gnu
```

#### Runtime Issues (ปัญหาขณะรันโปรแกรม)

**Issue: "Too many open files" (Linux)**
```bash
# Check current limit
ulimit -n

# Increase temporarily
ulimit -n 65536

# Increase permanently (add to /etc/security/limits.conf)
* soft nofile 65536
* hard nofile 65536

# Reload
sudo sysctl -p
```

**Issue: "Database lock" (RocksDB)**
```bash
# Check if another instance is running
ps aux | grep axionax-node

# Kill if necessary
kill -9 <PID>

# Or remove lock file (if no other instance)
rm -f /var/lib/axionax/testnet/LOCK
```

**Issue: "Connection refused" (P2P network)**
```bash
# Check if port is actually open
sudo netstat -tulpn | grep 30303

# Test connectivity
telnet bootstrap1.axionax.org 30303

# Check firewall
sudo ufw status
sudo ufw allow 30303/tcp
```

**Issue: High memory usage**
```bash
# Monitor memory
watch -n 1 'ps aux | grep axionax'

# Check for memory leaks (using valgrind)
cargo build
valgrind --leak-check=full ./target/debug/node

# Reduce RocksDB cache
export AXIONAX_ROCKSDB_CACHE_SIZE=256  # MB
```

#### Testing Issues (ปัญหาการทดสอบ)

**Issue: Tests fail intermittently**
```bash
# Run with single thread (avoid race conditions)
cargo test -- --test-threads=1

# Run with verbose output
RUST_LOG=debug cargo test -- --nocapture

# Run specific test multiple times
for i in {1..10}; do cargo test test_name || break; done
```

**Issue: "Connection pool timeout" in integration tests**
```bash
# Increase timeout in test code
#[tokio::test]
#[timeout(120000)]  // 2 minutes
async fn test_long_running() {
    // ...
}

# Or use longer timeout globally
export RUST_TEST_TIMEOUT=120
```

**Issue: Python tests can't import Rust module**
```bash
# Check if bridge is built
ls -la core/deai/lib/

# Should see: axionax_python.so (Linux) or .dylib (Mac) or .pyd (Windows)

# Rebuild if missing
cd core/bridge/rust-python
./build.sh

# Add to PYTHONPATH if needed
export PYTHONPATH=$PYTHONPATH:$(pwd)/core/deai/lib
```

#### Network/P2P Issues (ปัญหา network)

**Issue: "No peers connected"**
```bash
# Check network configuration
grep "bootstrap_nodes" config/testnet.toml

# Test DNS resolution
nslookup bootstrap1.axionax.org

# Check if bootstrap nodes are reachable
ping bootstrap1.axionax.org

# Try manual peer connection
curl -X POST http://localhost:8545 \
  -d '{"method":"admin_addPeer","params":["/ip4/1.2.3.4/tcp/30303/p2p/..."]}'
```

**Issue: "Gossipsub scoring threshold"**
```rust
// Adjust in core/core/network/src/manager.rs
let gossipsub_config = gossipsub::ConfigBuilder::default()
    .heartbeat_interval(Duration::from_secs(1))
    .validation_mode(ValidationMode::Strict)
    .message_id_fn(message_id_fn)
    // Lower thresholds for testnet
    .mesh_n_low(2)      // Min peers in mesh
    .mesh_n(4)          // Target peers
    .mesh_n_high(8)     // Max peers
    .build()
    .map_err(|e| anyhow!("Gossipsub config error: {}", e))?;
```

#### Performance Issues (ปัญหาประสิทธิภาพ)

**Issue: Slow block propagation**
```bash
# Check network latency
ping -c 10 peer1.axionax.org

# Monitor gossipsub stats
RUST_LOG=libp2p_gossipsub=debug cargo run

# Optimize gossipsub parameters
# In config file:
[network]
heartbeat_interval_ms = 700  # Default: 1000
mesh_message_deliveries_window_ms = 2000
```

**Issue: High CPU usage**
```bash
# Profile with flamegraph
cargo install flamegraph
sudo cargo flamegraph --bin node

# Check which functions are hot
perf record -F 99 -g ./target/release/node
perf report

# Optimize crypto operations (use Blake2s instead of SHA3)
grep -r "sha3_256" core/  # Find and replace with blake2s_256
```

**Issue: Database performance degradation**
```bash
# Compact RocksDB
curl -X POST http://localhost:8545/admin/compact_db

# Or programmatically
let state = StateDB::open("/var/lib/axionax/testnet")?;
state.compact_range(None, None)?;

# Adjust RocksDB settings
[state]
write_buffer_size = 67108864  # 64 MB
max_write_buffer_number = 3
target_file_size_base = 67108864
```

#### Docker Issues (ปัญหา Docker)

**Issue: "Cannot connect to Docker daemon"**
```bash
# Start Docker service
sudo systemctl start docker

# Add user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker
```

**Issue: Container keeps restarting**
```bash
# Check logs
docker logs axionax-node --tail 100

# Check health status
docker inspect axionax-node | jq '.[0].State.Health'

# Disable restart policy temporarily
docker update --restart=no axionax-node
```

**Issue: Out of disk space in container**
```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a
docker volume prune

# Increase volume size (recreate with larger volume)
docker volume create --opt size=50G axionax-data
```

---

## 📚 Key Documentation Files

**Read these FIRST for deep dives:**

| Topic                  | File                                      |
|------------------------|-------------------------------------------|
| Overall architecture   | `README.md`, `core/README.md`             |
| Development status     | `core/DEVELOPMENT_SUMMARY.md`             |
| Deployment guide       | `core/DEPLOYMENT_GUIDE.md`                |
| Security audit         | `core/SECURITY_AUDIT.md`                  |
| Multi-language design  | `core/docs/INTEGRATION_MIGRATION_GUIDE.md`|
| DeAI layer            | `core/deai/README.md`                     |
| DevOps setup          | `ops/deploy/README.md`                    |

---

## 🎨 Code Style Conventions

### Rust
- Use `rustfmt` defaults (no custom config)
- Max line length: 100 characters
- Prefer explicit types over `_` inference in public APIs
- Document all public functions with `///` comments

### Python
- Follow PEP 8 strictly
- Use Black formatter (line length: 100)
- Docstrings: Google style

### Shell Scripts
- Always start with `#!/bin/bash` and `set -euo pipefail`
- Use `shellcheck` for linting

---

## 🚦 Development Status Indicators

**Pre-merge checklist for PRs:**
- [ ] All tests pass locally
- [ ] No new clippy warnings
- [ ] Code formatted (run `cargo fmt --all`)
- [ ] Documentation updated if API changed
- [ ] Breaking changes noted in commit message
- [ ] Security implications considered

**Current project status:**
- 🟢 Core protocol: Production-ready
- 🟡 Testing: 70% complete (target: >80%)
- 🟡 Security audit: Pending professional review
- 🟠 Public testnet: Planned Q1 2026
- 🔴 Mainnet: Not launched (Q4 2026 target)

---

## 🤝 Contributing Workflow

1. **Start from an issue:** Check `issues/` for "good first issue" label
2. **Branch naming:** `feature/description` or `fix/bug-name`
3. **Commits:** Use conventional commits (`feat:`, `fix:`, `docs:`)
4. **Testing:** Add tests for new functionality
5. **PR description:** Link to issue, explain "why" not just "what"

**For AI agents:** When making multi-file changes, prioritize:
1. Core consensus logic (requires manual review)
2. Network protocol changes (breaking changes possible)
3. RPC API (backwards compatibility critical)
4. Documentation updates (can be done independently)

---

## 🔍 Finding Your Way Around

**Common tasks → Where to start:**

| Task                              | Starting Point                          |
|-----------------------------------|-----------------------------------------|
| Add new RPC method                | `core/core/rpc/src/lib.rs`              |
| Modify consensus logic            | `core/core/consensus/src/lib.rs`        |
| Add crypto primitive              | `core/core/crypto/src/`                 |
| Improve ML fraud detection        | `core/deai/fraud_detection.py`          |
| Deploy new service                | `ops/deploy/docker-compose.yaml`        |
| Add development tool              | `tools/devtools/scripts/`               |
| Update blockchain state schema    | `core/core/state/src/lib.rs`            |

**Understanding data flows:** Trace a transaction:
1. RPC receives: `core/core/rpc/src/lib.rs`
2. Validates: `core/core/blockchain/src/transaction.rs`
3. Adds to mempool: `core/core/blockchain/src/transaction_pool.rs`
4. Block production: `core/core/consensus/src/lib.rs`
5. Stores: `core/core/state/src/lib.rs`
6. Propagates: `core/core/network/src/manager.rs`

---

**Last Updated:** November 24, 2025  
**Maintainer:** Axionax Protocol Team  
**Questions?** Open an issue or check component-specific instructions in subdirectories.
