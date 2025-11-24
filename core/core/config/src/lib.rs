//! axionax Protocol Configuration Module
//!
//! Centralized configuration for all protocol parameters aligned with ARCHITECTURE v1.5

use serde::{Deserialize, Serialize};

/// PoPC (Proof of Probabilistic Checking) Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PoPCConfig {
    /// Sample size for challenge (s)
    /// Recommended: 600-1500 (ARCHITECTURE v1.5)
    pub sample_size: usize,

    /// Redundancy rate for replica jobs (β)
    /// Recommended: 2-3% (ARCHITECTURE v1.5)
    pub redundancy_rate: f64,

    /// Minimum confidence level for fraud detection
    /// Recommended: 0.99+ (99%+)
    pub min_confidence: f64,

    /// Fraud-proof window duration (Δt_fraud)
    /// Recommended: 3600s (1 hour)
    pub fraud_window_seconds: u64,

    /// VRF delay in blocks (k)
    /// Recommended: ≥2 blocks (ARCHITECTURE v1.5)
    pub vrf_delay_blocks: u64,

    /// False PASS penalty in basis points
    /// Recommended: ≥500 bps (5%) (ARCHITECTURE v1.5)
    pub false_pass_penalty_bps: u16,

    /// Minimum validator stake requirement
    pub min_validator_stake: u128,
}

impl Default for PoPCConfig {
    fn default() -> Self {
        Self {
            sample_size: 1000,                             // Mid-range of 600-1500
            redundancy_rate: 0.025,                        // 2.5% (β = 2-3%)
            min_confidence: 0.99,                          // 99% detection probability
            fraud_window_seconds: 3600,                    // 1 hour (Δt_fraud)
            vrf_delay_blocks: 2,                           // k ≥ 2 blocks
            false_pass_penalty_bps: 500,                   // 5% (≥500 bps)
            min_validator_stake: 10_000 * 10_u128.pow(18), // 10,000 AXX
        }
    }
}

/// ASR (Auto-Selection Router) Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ASRConfig {
    /// Top K candidates for VRF selection (K)
    /// Recommended: 64 (ARCHITECTURE v1.5)
    pub top_k: usize,

    /// Maximum quota per worker/org/ASN/region (q_max)
    /// Recommended: 10-15% per epoch (ARCHITECTURE v1.5)
    pub max_quota: f64,

    /// Exploration rate for newcomers (ε)
    /// Recommended: 5% (ARCHITECTURE v1.5)
    pub exploration_rate: f64,

    /// Newcomer fairness boost
    pub newcomer_boost: f64,

    /// Performance evaluation window in days
    pub performance_window_days: u32,

    /// Enable anti-collusion detection
    pub anti_collusion_enabled: bool,
}

impl Default for ASRConfig {
    fn default() -> Self {
        Self {
            top_k: 64,                    // K = 64 (ARCHITECTURE v1.5)
            max_quota: 0.125,             // 12.5% (q_max: 10-15%)
            exploration_rate: 0.05,       // 5% (ε = 5%)
            newcomer_boost: 0.1,          // 10% boost for newcomers
            performance_window_days: 30,  // EWMA 7-30 days
            anti_collusion_enabled: true, // Enabled by default
        }
    }
}

/// PPC (Posted Price Controller) Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PPCConfig {
    /// Target utilization (util*)
    /// Recommended: 0.7 (70%) (ARCHITECTURE v1.5)
    pub target_utilization: f64,

    /// Target queue time in seconds (q*)
    /// Recommended: 60s (ARCHITECTURE v1.5)
    pub target_queue_time_seconds: u64,

    /// Price adjustment rate (α)
    pub alpha: f64,

    /// Queue weight factor (β)
    pub beta: f64,

    /// Minimum price per class (p_min)
    pub min_price: f64,

    /// Maximum price per class (p_max)
    pub max_price: f64,

    /// Price adjustment interval
    pub adjustment_interval_seconds: u64,
}

impl Default for PPCConfig {
    fn default() -> Self {
        Self {
            target_utilization: 0.7,          // util* = 0.7 (70%)
            target_queue_time_seconds: 60,    // q* = 60s (1 minute)
            alpha: 0.1,                       // 10% adjustment rate
            beta: 0.05,                       // 5% queue weight
            min_price: 0.001,                 // p_min
            max_price: 10.0,                  // p_max
            adjustment_interval_seconds: 300, // 5 minutes
        }
    }
}

/// DA (Data Availability) Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DAConfig {
    /// Erasure coding rate
    /// Recommended: 1.5x (ARCHITECTURE v1.5)
    pub erasure_coding_rate: f64,

    /// Chunk size in KB for erasure coding
    pub chunk_size_kb: usize,

    /// Data availability window (Δt_DA)
    /// Must be available for challenge retrieval
    pub availability_window_seconds: u64,

    /// Replication factor for storage
    pub replication_factor: usize,

    /// Enable live DA audits
    pub live_audit_enabled: bool,

    /// Storage directory path
    pub storage_dir: String,
}

impl Default for DAConfig {
    fn default() -> Self {
        Self {
            erasure_coding_rate: 1.5,           // 1.5x redundancy
            chunk_size_kb: 256,                 // 256 KB chunks
            availability_window_seconds: 300,   // 5 minutes (Δt_DA)
            replication_factor: 3,              // 3x replication
            live_audit_enabled: true,           // Enable live audits
            storage_dir: "data/da".to_string(), // Default storage path
        }
    }
}

/// VRF (Verifiable Random Function) Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VRFConfig {
    /// Delay in blocks before VRF seed reveal (k)
    /// Recommended: ≥2 blocks (ARCHITECTURE v1.5)
    pub delay_blocks: u64,

    /// Use delayed VRF to prevent grinding
    pub use_delayed_vrf: bool,
}

impl Default for VRFConfig {
    fn default() -> Self {
        Self {
            delay_blocks: 2,       // k ≥ 2 blocks
            use_delayed_vrf: true, // Enabled by default
        }
    }
}

/// Network Configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkConfig {
    /// Chain ID (testnet: 86137, mainnet: 86150)
    pub chain_id: u64,

    /// Network name
    pub network_name: String,

    /// Block time in seconds
    pub block_time_seconds: u64,

    /// Maximum peers
    pub max_peers: usize,

    /// Bootstrap nodes
    pub bootstrap_nodes: Vec<String>,
}

impl NetworkConfig {
    /// Create testnet configuration (Chain ID: 86137)
    pub fn testnet() -> Self {
        Self {
            chain_id: 86137,
            network_name: "axionax-testnet".to_string(),
            block_time_seconds: 5,
            max_peers: 50,
            bootstrap_nodes: vec![],
        }
    }

    /// Create mainnet configuration (Chain ID: 86150)
    pub fn mainnet() -> Self {
        Self {
            chain_id: 86150,
            network_name: "axionax-mainnet".to_string(),
            block_time_seconds: 5,
            max_peers: 100,
            bootstrap_nodes: vec![],
        }
    }
}

/// Master Protocol Configuration
/// Combines all sub-configurations aligned with ARCHITECTURE v1.5
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolConfig {
    pub popc: PoPCConfig,
    pub asr: ASRConfig,
    pub ppc: PPCConfig,
    pub da: DAConfig,
    pub vrf: VRFConfig,
    pub network: NetworkConfig,
}

impl Default for ProtocolConfig {
    fn default() -> Self {
        Self {
            popc: PoPCConfig::default(),
            asr: ASRConfig::default(),
            ppc: PPCConfig::default(),
            da: DAConfig::default(),
            vrf: VRFConfig::default(),
            network: NetworkConfig::testnet(),
        }
    }
}

impl ProtocolConfig {
    /// Create testnet configuration
    pub fn testnet() -> Self {
        Self {
            network: NetworkConfig::testnet(),
            ..Default::default()
        }
    }

    /// Create mainnet configuration
    pub fn mainnet() -> Self {
        Self {
            network: NetworkConfig::mainnet(),
            ..Default::default()
        }
    }

    /// Load configuration from YAML file
    pub fn from_yaml(path: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let contents = std::fs::read_to_string(path)?;
        let config: ProtocolConfig = serde_yaml::from_str(&contents)?;
        Ok(config)
    }

    /// Save configuration to YAML file
    pub fn to_yaml(&self, path: &str) -> Result<(), Box<dyn std::error::Error>> {
        let yaml = serde_yaml::to_string(self)?;
        std::fs::write(path, yaml)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_popc_defaults() {
        let config = PoPCConfig::default();
        assert_eq!(config.sample_size, 1000);
        assert_eq!(config.redundancy_rate, 0.025); // 2.5%
        assert_eq!(config.min_confidence, 0.99);
        assert_eq!(config.fraud_window_seconds, 3600);
        assert_eq!(config.vrf_delay_blocks, 2);
        assert_eq!(config.false_pass_penalty_bps, 500); // 5%
    }

    #[test]
    fn test_asr_defaults() {
        let config = ASRConfig::default();
        assert_eq!(config.top_k, 64);
        assert_eq!(config.max_quota, 0.125); // 12.5%
        assert_eq!(config.exploration_rate, 0.05); // 5%
    }

    #[test]
    fn test_ppc_defaults() {
        let config = PPCConfig::default();
        assert_eq!(config.target_utilization, 0.7);
        assert_eq!(config.target_queue_time_seconds, 60);
    }

    #[test]
    fn test_da_defaults() {
        let config = DAConfig::default();
        assert_eq!(config.erasure_coding_rate, 1.5);
        assert_eq!(config.replication_factor, 3);
        assert!(config.live_audit_enabled);
    }

    #[test]
    fn test_vrf_defaults() {
        let config = VRFConfig::default();
        assert!(config.delay_blocks >= 2); // k ≥ 2
        assert!(config.use_delayed_vrf);
    }

    #[test]
    fn test_network_testnet() {
        let config = NetworkConfig::testnet();
        assert_eq!(config.chain_id, 86137);
        assert_eq!(config.network_name, "axionax-testnet");
    }

    #[test]
    fn test_network_mainnet() {
        let config = NetworkConfig::mainnet();
        assert_eq!(config.chain_id, 86150);
        assert_eq!(config.network_name, "axionax-mainnet");
    }

    #[test]
    fn test_protocol_config_default() {
        let config = ProtocolConfig::default();
        assert_eq!(config.network.chain_id, 86137); // Default is testnet
        assert_eq!(config.popc.sample_size, 1000);
        assert_eq!(config.asr.top_k, 64);
    }
}
