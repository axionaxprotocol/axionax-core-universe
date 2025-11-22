//! Block and Transaction Validation
//!
//! Comprehensive validation logic for blocks and transactions

use crate::{Block, Transaction};
use crypto::signature;
use ed25519_dalek::VerifyingKey;
use thiserror::Error;
use tracing::{debug, warn};

/// Validation errors
#[derive(Error, Debug)]
pub enum ValidationError {
    #[error("Invalid block number: expected {expected}, got {actual}")]
    InvalidBlockNumber { expected: u64, actual: u64 },

    #[error("Invalid parent hash")]
    InvalidParentHash,

    #[error("Invalid block hash")]
    InvalidBlockHash,

    #[error("Block timestamp too old")]
    TimestampTooOld,

    #[error("Block timestamp in future")]
    TimestampInFuture,

    #[error("Block too large: {size} bytes (max: {max})")]
    BlockTooLarge { size: usize, max: usize },

    #[error("Too many transactions: {count} (max: {max})")]
    TooManyTransactions { count: usize, max: usize },

    #[error("Invalid transaction signature")]
    InvalidSignature,

    #[error("Invalid transaction nonce: expected {expected}, got {actual}")]
    InvalidNonce { expected: u64, actual: u64 },

    #[error("Insufficient gas: {provided} < {required}")]
    InsufficientGas { provided: u64, required: u64 },

    #[error("Gas limit exceeded: {used} > {limit}")]
    GasLimitExceeded { used: u64, limit: u64 },

    #[error("Invalid gas price: {price} (min: {min_price})")]
    InvalidGasPrice { price: u128, min_price: u128 },

    #[error("Transaction value overflow")]
    ValueOverflow,

    #[error("Invalid address format: {0}")]
    InvalidAddress(String),

    #[error("Zero address not allowed")]
    ZeroAddress,

    #[error("Invalid state root")]
    InvalidStateRoot,
}

pub type Result<T> = std::result::Result<T, ValidationError>;

/// Block validator configuration
#[derive(Debug, Clone)]
pub struct ValidationConfig {
    /// Maximum block size in bytes
    pub max_block_size: usize,
    /// Maximum transactions per block
    pub max_transactions_per_block: usize,
    /// Maximum block timestamp drift (seconds into future)
    pub max_timestamp_drift: u64,
    /// Minimum gas price (wei)
    pub min_gas_price: u128,
    /// Block gas limit
    pub block_gas_limit: u64,
    /// Minimum transaction gas limit
    pub min_transaction_gas: u64,
}

impl Default for ValidationConfig {
    fn default() -> Self {
        Self {
            max_block_size: 1_048_576, // 1 MB
            max_transactions_per_block: 10_000,
            max_timestamp_drift: 15, // 15 seconds
            min_gas_price: 1_000_000_000, // 1 Gwei
            block_gas_limit: 30_000_000,
            min_transaction_gas: 21_000,
        }
    }
}

/// Block validator
pub struct BlockValidator {
    config: ValidationConfig,
}

impl BlockValidator {
    /// Create a new block validator
    pub fn new(config: ValidationConfig) -> Self {
        Self { config }
    }

    /// Validate a block completely
    pub fn validate_block(&self, block: &Block, parent: Option<&Block>) -> Result<()> {
        debug!("Validating block #{}", block.number);

        // Validate block number
        if let Some(parent_block) = parent {
            if block.number != parent_block.number + 1 {
                return Err(ValidationError::InvalidBlockNumber {
                    expected: parent_block.number + 1,
                    actual: block.number,
                });
            }

            // Validate parent hash
            if block.parent_hash != parent_block.hash {
                warn!("Invalid parent hash in block #{}", block.number);
                return Err(ValidationError::InvalidParentHash);
            }
        } else if block.number != 0 {
            // If no parent provided, block must be genesis
            return Err(ValidationError::InvalidBlockNumber {
                expected: 0,
                actual: block.number,
            });
        }

        // Validate timestamp
        self.validate_timestamp(block)?;

        // Validate size
        self.validate_block_size(block)?;

        // Validate transactions
        self.validate_transactions(block)?;

        // Validate gas usage
        self.validate_gas(block)?;

        // Validate block hash (basic check)
        if block.hash == [0u8; 32] && block.number != 0 {
            return Err(ValidationError::InvalidBlockHash);
        }

        debug!("Block #{} validation passed", block.number);
        Ok(())
    }

    /// Validate block timestamp
    fn validate_timestamp(&self, block: &Block) -> Result<()> {
        use std::time::{SystemTime, UNIX_EPOCH};

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        // Block timestamp cannot be too far in the future
        if block.timestamp > now + self.config.max_timestamp_drift {
            return Err(ValidationError::TimestampInFuture);
        }

        // Block timestamp should not be zero (except genesis)
        if block.timestamp == 0 && block.number != 0 {
            return Err(ValidationError::TimestampTooOld);
        }

        Ok(())
    }

    /// Validate block size
    fn validate_block_size(&self, block: &Block) -> Result<()> {
        // Rough estimate of block size
        let size = 32 + 32 + 8 + 32 + 8 + 8 + // Basic block fields
                   block.proposer.len() +
                   block.transactions.len() * 150; // Approximate tx size

        if size > self.config.max_block_size {
            return Err(ValidationError::BlockTooLarge {
                size,
                max: self.config.max_block_size,
            });
        }

        Ok(())
    }

    /// Validate all transactions in block
    fn validate_transactions(&self, block: &Block) -> Result<()> {
        // Check transaction count
        if block.transactions.len() > self.config.max_transactions_per_block {
            return Err(ValidationError::TooManyTransactions {
                count: block.transactions.len(),
                max: self.config.max_transactions_per_block,
            });
        }

        // Validate each transaction
        let tx_validator = TransactionValidator::new(self.config.clone());
        for tx in &block.transactions {
            tx_validator.validate_transaction(tx)?;
        }

        Ok(())
    }

    /// Validate gas usage
    fn validate_gas(&self, block: &Block) -> Result<()> {
        // Check block gas limit
        if block.gas_limit > self.config.block_gas_limit {
            return Err(ValidationError::GasLimitExceeded {
                used: block.gas_limit,
                limit: self.config.block_gas_limit,
            });
        }

        // Check gas used doesn't exceed limit
        if block.gas_used > block.gas_limit {
            return Err(ValidationError::GasLimitExceeded {
                used: block.gas_used,
                limit: block.gas_limit,
            });
        }

        Ok(())
    }
}

/// Transaction validator
pub struct TransactionValidator {
    config: ValidationConfig,
}

impl TransactionValidator {
    /// Create a new transaction validator
    pub fn new(config: ValidationConfig) -> Self {
        Self { config }
    }

    /// Validate a transaction
    pub fn validate_transaction(&self, tx: &Transaction) -> Result<()> {
        debug!("Validating transaction {:?}", &tx.hash[..8]);

        // Validate addresses
        self.validate_address(&tx.from)?;
        self.validate_address(&tx.to)?;

        // Validate gas
        if tx.gas_limit < self.config.min_transaction_gas {
            return Err(ValidationError::InsufficientGas {
                provided: tx.gas_limit,
                required: self.config.min_transaction_gas,
            });
        }

        // Validate gas price
        if tx.gas_price < self.config.min_gas_price {
            return Err(ValidationError::InvalidGasPrice {
                price: tx.gas_price,
                min_price: self.config.min_gas_price,
            });
        }

        // Validate value doesn't overflow
        if tx.value == u128::MAX {
            return Err(ValidationError::ValueOverflow);
        }

        // Validate hash is not zero
        if tx.hash == [0u8; 32] {
            return Err(ValidationError::InvalidSignature);
        }

        Ok(())
    }

    /// Validate transaction signature
    pub fn validate_signature(
        &self,
        tx: &Transaction,
        signature: &[u8],
        public_key: &VerifyingKey,
    ) -> Result<()> {
        // Create transaction message to verify
        let mut message = Vec::new();
        message.extend_from_slice(&tx.hash);
        message.extend_from_slice(tx.from.as_bytes());
        message.extend_from_slice(tx.to.as_bytes());
        message.extend_from_slice(&tx.value.to_le_bytes());
        message.extend_from_slice(&tx.nonce.to_le_bytes());

        if !signature::verify(public_key, &message, signature) {
            return Err(ValidationError::InvalidSignature);
        }

        Ok(())
    }

    /// Validate address format (basic check)
    fn validate_address(&self, address: &str) -> Result<()> {
        // Check if address starts with 0x
        if !address.starts_with("0x") {
            return Err(ValidationError::InvalidAddress(address.to_string()));
        }

        // Check if address is zero address
        if address == "0x0000000000000000000000000000000000000000" {
            return Err(ValidationError::ZeroAddress);
        }

        // Check length (0x + 40 hex chars = 42 total)
        if address.len() != 42 {
            return Err(ValidationError::InvalidAddress(address.to_string()));
        }

        // Check if all characters after 0x are valid hex
        if !address[2..].chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(ValidationError::InvalidAddress(address.to_string()));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_valid_block(number: u64) -> Block {
        Block {
            number,
            hash: [1u8; 32],
            parent_hash: if number > 0 { [2u8; 32] } else { [0u8; 32] },
            timestamp: 1700000000,
            proposer: "0x1234567890123456789012345678901234567890".to_string(),
            transactions: vec![],
            state_root: [3u8; 32],
            gas_used: 0,
            gas_limit: 10_000_000,
        }
    }

    fn create_valid_transaction() -> Transaction {
        Transaction {
            hash: [1u8; 32],
            from: "0x1234567890123456789012345678901234567890".to_string(),
            to: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd".to_string(),
            value: 1000,
            gas_price: 20_000_000_000,
            gas_limit: 21_000,
            nonce: 1,
            data: vec![],
        }
    }

    #[test]
    fn test_validate_valid_block() {
        let config = ValidationConfig::default();
        let validator = BlockValidator::new(config);

        let block = create_valid_block(1);
        let parent = create_valid_block(0);

        assert!(validator.validate_block(&block, Some(&parent)).is_ok());
    }

    #[test]
    fn test_validate_genesis_block() {
        let config = ValidationConfig::default();
        let validator = BlockValidator::new(config);

        let genesis = create_valid_block(0);
        assert!(validator.validate_block(&genesis, None).is_ok());
    }

    #[test]
    fn test_invalid_block_number() {
        let config = ValidationConfig::default();
        let validator = BlockValidator::new(config);

        let mut block = create_valid_block(5); // Wrong number
        let parent = create_valid_block(0);

        let result = validator.validate_block(&block, Some(&parent));
        assert!(matches!(result, Err(ValidationError::InvalidBlockNumber { .. })));
    }

    #[test]
    fn test_invalid_parent_hash() {
        let config = ValidationConfig::default();
        let validator = BlockValidator::new(config);

        let block = create_valid_block(1);
        let mut parent = create_valid_block(0);
        parent.hash = [99u8; 32]; // Different hash

        let result = validator.validate_block(&block, Some(&parent));
        assert!(matches!(result, Err(ValidationError::InvalidParentHash)));
    }

    #[test]
    fn test_validate_valid_transaction() {
        let config = ValidationConfig::default();
        let validator = TransactionValidator::new(config);

        let tx = create_valid_transaction();
        assert!(validator.validate_transaction(&tx).is_ok());
    }

    #[test]
    fn test_invalid_gas_limit() {
        let config = ValidationConfig::default();
        let validator = TransactionValidator::new(config);

        let mut tx = create_valid_transaction();
        tx.gas_limit = 1000; // Too low

        let result = validator.validate_transaction(&tx);
        assert!(matches!(result, Err(ValidationError::InsufficientGas { .. })));
    }

    #[test]
    fn test_invalid_gas_price() {
        let config = ValidationConfig::default();
        let validator = TransactionValidator::new(config);

        let mut tx = create_valid_transaction();
        tx.gas_price = 100; // Too low

        let result = validator.validate_transaction(&tx);
        assert!(matches!(result, Err(ValidationError::InvalidGasPrice { .. })));
    }

    #[test]
    fn test_validate_address() {
        let config = ValidationConfig::default();
        let validator = TransactionValidator::new(config);

        // Valid address
        assert!(validator.validate_address("0x1234567890123456789012345678901234567890").is_ok());

        // Invalid: no 0x prefix
        assert!(validator.validate_address("1234567890123456789012345678901234567890").is_err());

        // Invalid: zero address
        assert!(validator.validate_address("0x0000000000000000000000000000000000000000").is_err());

        // Invalid: wrong length
        assert!(validator.validate_address("0x1234").is_err());

        // Invalid: non-hex characters
        assert!(validator.validate_address("0xZZZZ567890123456789012345678901234567890").is_err());
    }

    #[test]
    fn test_block_too_many_transactions() {
        let mut config = ValidationConfig::default();
        config.max_transactions_per_block = 2;
        let validator = BlockValidator::new(config);

        let mut block = create_valid_block(1);
        block.transactions = vec![
            create_valid_transaction(),
            create_valid_transaction(),
            create_valid_transaction(), // One too many
        ];

        let result = validator.validate_transactions(&block);
        assert!(matches!(result, Err(ValidationError::TooManyTransactions { .. })));
    }

    #[test]
    fn test_gas_limit_exceeded() {
        let config = ValidationConfig::default();
        let validator = BlockValidator::new(config);

        let mut block = create_valid_block(1);
        block.gas_used = 50_000_000;
        block.gas_limit = 40_000_000;

        let result = validator.validate_gas(&block);
        assert!(matches!(result, Err(ValidationError::GasLimitExceeded { .. })));
    }
}
