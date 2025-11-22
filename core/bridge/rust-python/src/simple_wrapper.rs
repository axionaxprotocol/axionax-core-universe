// Simplified wrappers to avoid deep Rust API exposure to Python

use pyo3::prelude::*;
use consensus::ConsensusConfig;
use blockchain::BlockchainConfig;

/// Get default consensus config
pub fn default_consensus_config() -> ConsensusConfig {
    ConsensusConfig {
        sample_size: 1000,              // Recommended: 600-1500 (ARCHITECTURE v1.5)
        min_confidence: 0.99,            // 99%+ required detection probability  
        fraud_window_blocks: 720,        // ~3600s @ 5s/block (Δt_fraud)
        min_validator_stake: 100_000,    // Minimum stake requirement
        false_pass_penalty_bps: 500,     // 5% (≥500 bps per ARCHITECTURE v1.5)
    }
}

/// Get default blockchain config
pub fn default_blockchain_config() -> BlockchainConfig {
    BlockchainConfig {
        block_time_secs: 12,
        max_block_size: 1_000_000,
        gas_limit: 30_000_000,
    }
}
