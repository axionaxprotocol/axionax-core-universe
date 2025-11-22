# AxionAx Core API Reference

## Overview

AxionAx Core provides a modular blockchain infrastructure with Proof of Provable Computation (PoPC), Auto Selection Router (ASR), and Predictive Pricing Controller (PPC).

---

## Rust API

### Consensus Module

#### `ConsensusConfig`

Configuration for PoPC consensus mechanism.

```rust
pub struct ConsensusConfig {
    pub sample_size: usize,              // Validator sample size (600-1500)
    pub redundancy_rate: f64,             // Redundancy rate (2.5%)
    pub min_confidence: f64,              // Minimum confidence threshold (0.99)
    pub fraud_window_blocks: u64,         // Fraud detection window (720 blocks)
    pub vrf_delay_blocks: u64,            // VRF delay (2 blocks)
    pub false_pass_penalty_bps: u64,      // False pass penalty (500 bps = 5%)
    pub min_validator_stake: u128,        // Minimum stake requirement
}
```

**Example:**

```rust
use axionax_consensus::ConsensusConfig;

let config = ConsensusConfig {
    sample_size: 1000,
    redundancy_rate: 0.025,
    min_confidence: 0.99,
    fraud_window_blocks: 720,
    vrf_delay_blocks: 2,
    false_pass_penalty_bps: 500,
    min_validator_stake: 1_000_000,
};
```

#### `Blockchain`

Main blockchain state management.

```rust
pub struct Blockchain {
    pub chain: Vec<Block>,
    pub pending_transactions: Vec<Transaction>,
    pub validators: HashMap<String, Validator>,
}

impl Blockchain {
    pub fn new() -> Self;
    pub fn add_block(&mut self, block: Block) -> Result<(), BlockchainError>;
    pub fn validate_block(&self, block: &Block) -> Result<(), BlockchainError>;
    pub fn get_latest_block(&self) -> Option<&Block>;
}
```

**Example:**

```rust
use axionax_blockchain::Blockchain;

let mut chain = Blockchain::new();
let block = Block::new(/* ... */);
chain.add_block(block)?;
```

---

### Crypto Module

#### `sign_message`

Sign a message with Ed25519.

```rust
pub fn sign_message(
    private_key: &[u8],
    message: &[u8]
) -> Result<Vec<u8>, CryptoError>
```

**Example:**

```rust
use axionax_crypto::sign_message;

let signature = sign_message(&private_key, b"Hello AxionAx")?;
```

#### `verify_signature`

Verify an Ed25519 signature.

```rust
pub fn verify_signature(
    public_key: &[u8],
    message: &[u8],
    signature: &[u8]
) -> Result<bool, CryptoError>
```

---

### Network Module

#### `P2PNetwork`

Peer-to-peer network management.

```rust
pub struct P2PNetwork {
    pub local_peer_id: PeerId,
    pub swarm: Swarm<NetworkBehaviour>,
}

impl P2PNetwork {
    pub async fn new(config: NetworkConfig) -> Result<Self, NetworkError>;
    pub async fn broadcast(&mut self, message: Message) -> Result<(), NetworkError>;
    pub async fn connect_peer(&mut self, peer_id: PeerId) -> Result<(), NetworkError>;
}
```

**Example:**

```rust
use axionax_network::{P2PNetwork, NetworkConfig};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = NetworkConfig::default();
    let mut network = P2PNetwork::new(config).await?;
    
    network.broadcast(Message::NewBlock(block)).await?;
    Ok(())
}
```

---

### RPC Module

#### JSON-RPC Methods

##### `eth_getBlockByNumber`

Get block by number.

**Parameters:**
- `block_number`: `String` - Block number in hex or "latest"
- `full_transactions`: `bool` - If true, return full transaction objects

**Returns:** `Block`

**Example:**

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getBlockByNumber",
    "params": ["latest", true],
    "id": 1
  }'
```

##### `eth_getTransactionReceipt`

Get transaction receipt.

**Parameters:**
- `transaction_hash`: `String` - Transaction hash

**Returns:** `TransactionReceipt`

##### `eth_sendRawTransaction`

Send raw signed transaction.

**Parameters:**
- `signed_tx`: `String` - Signed transaction in hex

**Returns:** `String` - Transaction hash

---

## Python API

### DeAI Module

#### `AutoSelectionRouter`

Auto Selection Router for worker assignment.

```python
class AutoSelectionRouter:
    def __init__(
        self,
        top_k: int = 64,
        max_quota: float = 0.125,
        exploration_rate: float = 0.05,
        newcomer_boost: float = 0.1
    )
```

**Example:**

```python
from deai.asr import AutoSelectionRouter

asr = AutoSelectionRouter(
    top_k=64,
    max_quota=0.125,
    exploration_rate=0.05
)

# Select workers for task
workers = asr.select_workers(
    task_requirements={'cpu': 4, 'memory': 8192},
    num_workers=10
)
```

#### Methods

##### `calculate_suitability`

Calculate hardware suitability score.

```python
def calculate_suitability(
    self,
    worker: Worker,
    requirements: dict
) -> float
```

##### `calculate_performance`

Calculate historical performance score.

```python
def calculate_performance(
    self,
    worker: Worker,
    performance_window: int = 100
) -> float
```

##### `select_workers`

Select optimal workers for task.

```python
def select_workers(
    self,
    task_requirements: dict,
    num_workers: int
) -> List[Worker]
```

---

## TypeScript SDK API

### AxionAxProvider

Main provider for interacting with AxionAx blockchain.

```typescript
import { AxionAxProvider } from '@axionax/sdk';

const provider = new AxionAxProvider('http://localhost:8545');
```

#### Methods

##### `getBlockNumber`

Get current block number.

```typescript
async getBlockNumber(): Promise<number>
```

**Example:**

```typescript
const blockNumber = await provider.getBlockNumber();
console.log(`Current block: ${blockNumber}`);
```

##### `getBlock`

Get block by number or hash.

```typescript
async getBlock(
  blockHashOrNumber: string | number
): Promise<Block>
```

##### `getTransaction`

Get transaction by hash.

```typescript
async getTransaction(
  transactionHash: string
): Promise<Transaction>
```

##### `sendTransaction`

Send transaction.

```typescript
async sendTransaction(
  transaction: TransactionRequest
): Promise<TransactionResponse>
```

**Example:**

```typescript
const tx = await provider.sendTransaction({
  to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  value: ethers.parseEther('1.0'),
  gasLimit: 21000
});

await tx.wait();
```

---

### Wallet

Wallet management.

```typescript
import { Wallet } from '@axionax/sdk';

const wallet = new Wallet(privateKey, provider);
```

#### Methods

##### `getAddress`

Get wallet address.

```typescript
getAddress(): string
```

##### `signMessage`

Sign a message.

```typescript
async signMessage(message: string): Promise<string>
```

##### `signTransaction`

Sign a transaction.

```typescript
async signTransaction(
  transaction: TransactionRequest
): Promise<string>
```

---

## Configuration API

### ProtocolConfig

Unified protocol configuration.

```rust
pub struct ProtocolConfig {
    pub popc: PoPCConfig,
    pub asr: ASRConfig,
    pub ppc: PPCConfig,
    pub da: DAConfig,
    pub vrf: VRFConfig,
    pub network: NetworkConfig,
}

impl ProtocolConfig {
    pub fn from_yaml(path: &str) -> Result<Self, ConfigError>;
    pub fn to_yaml(&self, path: &str) -> Result<(), ConfigError>;
    pub fn default_testnet() -> Self;
    pub fn default_mainnet() -> Self;
}
```

**Example YAML:**

```yaml
popc:
  sample_size: 1000
  redundancy_rate: 0.025
  min_confidence: 0.99
  fraud_window_seconds: 3600
  vrf_delay_blocks: 2
  false_pass_penalty_bps: 500

asr:
  top_k: 64
  max_quota: 0.125
  exploration_rate: 0.05
  newcomer_boost: 0.1
  anti_collusion_enabled: true

network:
  chain_id: 86137
  network_name: "AxionAx Testnet"
  block_time_seconds: 5
  max_peers: 50
```

**Load config:**

```rust
use axionax_config::ProtocolConfig;

let config = ProtocolConfig::from_yaml("config.yaml")?;
```

---

## Error Handling

### Common Error Types

```rust
pub enum AxionAxError {
    BlockchainError(String),
    ConsensusError(String),
    NetworkError(String),
    CryptoError(String),
    ConfigError(String),
}
```

**Example:**

```rust
use axionax_core::AxionAxError;

fn process_block(block: Block) -> Result<(), AxionAxError> {
    // Validate block
    if !block.is_valid() {
        return Err(AxionAxError::BlockchainError(
            "Invalid block".to_string()
        ));
    }
    Ok(())
}
```

---

## Events

### Block Events

Subscribe to new blocks.

**Rust:**

```rust
let mut block_stream = blockchain.subscribe_blocks();
while let Some(block) = block_stream.next().await {
    println!("New block: {}", block.number);
}
```

**TypeScript:**

```typescript
provider.on('block', (blockNumber) => {
  console.log(`New block: ${blockNumber}`);
});
```

---

## See Also

- [Architecture Documentation](ARCHITECTURE.md)
- [Quick Start Guide](../QUICK_START.md)
- [Examples](../examples/)
- [GitHub Repository](https://github.com/axionaxprotocol/axionax-core)
