//! Transaction Pool (Mempool)
//!
//! Manages pending transactions before they are included in blocks

use std::collections::{HashMap, BTreeMap};
use std::sync::Arc;
use tokio::sync::RwLock;
use thiserror::Error;
use tracing::{debug, info};

use crate::{Transaction, validation::{TransactionValidator, ValidationConfig}};

/// Transaction pool errors
#[derive(Error, Debug)]
pub enum PoolError {
    #[error("Transaction already exists in pool")]
    AlreadyExists,

    #[error("Pool is full (max: {0})")]
    PoolFull(usize),

    #[error("Transaction validation failed: {0}")]
    ValidationFailed(String),

    #[error("Nonce too low: expected {expected}, got {actual}")]
    NonceTooLow { expected: u64, actual: u64 },

    #[error("Nonce too high: expected {expected}, got {actual}")]
    NonceTooHigh { expected: u64, actual: u64 },

    #[error("Insufficient balance")]
    InsufficientBalance,

    #[error("Gas price too low: {price} (min: {min_price})")]
    GasPriceTooLow { price: u128, min_price: u128 },

    #[error("Transaction not found")]
    NotFound,
}

pub type Result<T> = std::result::Result<T, PoolError>;

/// Transaction pool configuration
#[derive(Debug, Clone)]
pub struct PoolConfig {
    /// Maximum number of transactions in pool
    pub max_pool_size: usize,
    /// Maximum number of transactions per account
    pub max_per_account: usize,
    /// Maximum nonce gap allowed
    pub max_nonce_gap: u64,
    /// Minimum gas price multiplier for replacement (in basis points)
    pub replacement_price_bump: u16, // e.g., 1000 = 10%
}

impl Default for PoolConfig {
    fn default() -> Self {
        Self {
            max_pool_size: 10_000,
            max_per_account: 100,
            max_nonce_gap: 10,
            replacement_price_bump: 1000, // 10%
        }
    }
}

/// Transaction pool statistics
#[derive(Debug, Clone, Default)]
pub struct PoolStats {
    pub total_transactions: usize,
    pub pending_transactions: usize,
    pub queued_transactions: usize,
    pub total_added: u64,
    pub total_removed: u64,
    pub total_rejected: u64,
}

/// Pending transaction with priority
#[derive(Debug, Clone)]
struct PendingTransaction {
    transaction: Transaction,
    #[allow(dead_code)] // Keep for future use (e.g., expiration)
    added_at: u64,
    gas_price: u128,
}

/// Account transaction queue
#[derive(Debug, Clone)]
struct AccountQueue {
    /// Pending transactions (nonce is sequential from current)
    pending: BTreeMap<u64, PendingTransaction>,
    /// Queued transactions (nonce gap exists)
    queued: BTreeMap<u64, PendingTransaction>,
    /// Current nonce for this account
    current_nonce: u64,
}

impl AccountQueue {
    fn new(current_nonce: u64) -> Self {
        Self {
            pending: BTreeMap::new(),
            queued: BTreeMap::new(),
            current_nonce,
        }
    }

    fn len(&self) -> usize {
        self.pending.len() + self.queued.len()
    }

    fn is_empty(&self) -> bool {
        self.pending.is_empty() && self.queued.is_empty()
    }
}

/// Transaction pool
pub struct TransactionPool {
    /// Configuration
    config: PoolConfig,
    /// Validation config
    #[allow(dead_code)] // Keep for future use or reference
    validation_config: ValidationConfig,
    /// Transaction validator
    validator: TransactionValidator,
    /// Transactions by account
    accounts: Arc<RwLock<HashMap<String, AccountQueue>>>,
    /// Transaction hash to account mapping
    tx_to_account: Arc<RwLock<HashMap<[u8; 32], String>>>,
    /// Pool statistics
    stats: Arc<RwLock<PoolStats>>,
}

impl TransactionPool {
    /// Create a new transaction pool
    pub fn new(config: PoolConfig, validation_config: ValidationConfig) -> Self {
        Self {
            validator: TransactionValidator::new(validation_config.clone()),
            config,
            validation_config,
            accounts: Arc::new(RwLock::new(HashMap::new())),
            tx_to_account: Arc::new(RwLock::new(HashMap::new())),
            stats: Arc::new(RwLock::new(PoolStats::default())),
        }
    }

    /// Add a transaction to the pool
    pub async fn add_transaction(&self, tx: Transaction) -> Result<()> {
        debug!("Adding transaction {:?} to pool", &tx.hash[..8]);

        // Validate transaction
        self.validator.validate_transaction(&tx)
            .map_err(|e| PoolError::ValidationFailed(e.to_string()))?;

        let mut accounts = self.accounts.write().await;
        let mut tx_to_account = self.tx_to_account.write().await;
        let mut stats = self.stats.write().await;

        // Check if transaction already exists
        if tx_to_account.contains_key(&tx.hash) {
            stats.total_rejected += 1;
            return Err(PoolError::AlreadyExists);
        }

        // Check pool size
        if tx_to_account.len() >= self.config.max_pool_size {
            stats.total_rejected += 1;
            return Err(PoolError::PoolFull(self.config.max_pool_size));
        }

        // Get or create account queue
        let account = tx.from.clone();
        let queue = accounts.entry(account.clone())
            .or_insert_with(|| AccountQueue::new(tx.nonce));

        // Check per-account limit
        if queue.len() >= self.config.max_per_account {
            stats.total_rejected += 1;
            return Err(PoolError::PoolFull(self.config.max_per_account));
        }

        // Check nonce
        let expected_nonce = queue.current_nonce + queue.pending.len() as u64;

        if tx.nonce < queue.current_nonce {
            stats.total_rejected += 1;
            return Err(PoolError::NonceTooLow {
                expected: queue.current_nonce,
                actual: tx.nonce,
            });
        }

        if tx.nonce > expected_nonce + self.config.max_nonce_gap {
            stats.total_rejected += 1;
            return Err(PoolError::NonceTooHigh {
                expected: expected_nonce,
                actual: tx.nonce,
            });
        }

        // Create pending transaction
        let pending_tx = PendingTransaction {
            transaction: tx.clone(),
            added_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            gas_price: tx.gas_price,
        };

        // Add to appropriate queue
        if tx.nonce == expected_nonce {
            // Add to pending (sequential nonce)
            queue.pending.insert(tx.nonce, pending_tx);
        } else {
            // Add to queued (nonce gap exists)
            queue.queued.insert(tx.nonce, pending_tx);
        }

        // Update mappings
        tx_to_account.insert(tx.hash, account);

        // Update stats
        stats.total_added += 1;
        stats.total_transactions = tx_to_account.len();
        stats.pending_transactions = accounts.values()
            .map(|q| q.pending.len())
            .sum();
        stats.queued_transactions = accounts.values()
            .map(|q| q.queued.len())
            .sum();

        info!("Transaction {:?} added to pool", &tx.hash[..8]);
        Ok(())
    }

    /// Remove a transaction from the pool
    pub async fn remove_transaction(&self, tx_hash: &[u8; 32]) -> Result<Transaction> {
        let mut accounts = self.accounts.write().await;
        let mut tx_to_account = self.tx_to_account.write().await;
        let mut stats = self.stats.write().await;

        // Find account
        let account = tx_to_account.remove(tx_hash)
            .ok_or(PoolError::NotFound)?;

        // Find and remove transaction
        let queue = accounts.get_mut(&account)
            .ok_or(PoolError::NotFound)?;

        let tx = queue.pending.iter()
            .find(|(_, ptx)| ptx.transaction.hash == *tx_hash)
            .map(|(nonce, ptx)| (*nonce, ptx.transaction.clone()))
            .or_else(|| {
                queue.queued.iter()
                    .find(|(_, ptx)| ptx.transaction.hash == *tx_hash)
                    .map(|(nonce, ptx)| (*nonce, ptx.transaction.clone()))
            })
            .ok_or(PoolError::NotFound)?;

        queue.pending.remove(&tx.0);
        queue.queued.remove(&tx.0);

        // Clean up empty queue
        if queue.is_empty() {
            accounts.remove(&account);
        }

        // Update stats
        stats.total_removed += 1;
        stats.total_transactions = tx_to_account.len();

        Ok(tx.1)
    }

    /// Get pending transactions for block production
    pub async fn get_pending_transactions(&self, limit: usize) -> Vec<Transaction> {
        let accounts = self.accounts.read().await;

        let mut transactions = Vec::new();
        let mut pending: Vec<_> = accounts.values()
            .flat_map(|queue| {
                queue.pending.values()
                    .map(|ptx| (ptx.gas_price, ptx.clone()))
            })
            .collect();

        // Sort by gas price (highest first)
        pending.sort_by(|a, b| b.0.cmp(&a.0));

        // Take top transactions
        for (_, ptx) in pending.into_iter().take(limit) {
            transactions.push(ptx.transaction);
        }

        transactions
    }

    /// Update account nonce (after block execution)
    pub async fn update_nonce(&self, account: &str, new_nonce: u64) {
        let mut accounts = self.accounts.write().await;
        let mut tx_to_account = self.tx_to_account.write().await;

        if let Some(queue) = accounts.get_mut(account) {
            queue.current_nonce = new_nonce;

            // Collect transaction hashes to remove from mapping
            let removed_hashes: Vec<[u8; 32]> = queue.pending.iter()
                .filter(|(&nonce, _)| nonce < new_nonce)
                .map(|(_, ptx)| ptx.transaction.hash)
                .collect();

            // Remove transactions with old nonces from queue
            queue.pending.retain(|&nonce, _| nonce >= new_nonce);

            // Remove from tx_to_account mapping
            for hash in removed_hashes {
                tx_to_account.remove(&hash);
            }

            // Also remove old queued transactions
            let removed_queued: Vec<[u8; 32]> = queue.queued.iter()
                .filter(|(&nonce, _)| nonce < new_nonce)
                .map(|(_, ptx)| ptx.transaction.hash)
                .collect();

            queue.queued.retain(|&nonce, _| nonce >= new_nonce);

            for hash in removed_queued {
                tx_to_account.remove(&hash);
            }

            // Promote queued transactions to pending
            let to_promote: Vec<_> = queue.queued.iter()
                .filter(|(&nonce, _)| nonce == new_nonce + queue.pending.len() as u64)
                .map(|(&nonce, ptx)| (nonce, ptx.clone()))
                .collect();

            for (nonce, ptx) in to_promote {
                queue.queued.remove(&nonce);
                queue.pending.insert(nonce, ptx);
            }

            // Note: Don't remove account from map, keep current_nonce tracking
        }
    }

    /// Get pool statistics
    pub async fn stats(&self) -> PoolStats {
        self.stats.read().await.clone()
    }

    /// Get transaction by hash
    pub async fn get_transaction(&self, tx_hash: &[u8; 32]) -> Option<Transaction> {
        let tx_to_account = self.tx_to_account.read().await;
        let accounts = self.accounts.read().await;

        let account = tx_to_account.get(tx_hash)?;
        let queue = accounts.get(account)?;

        queue.pending.values()
            .chain(queue.queued.values())
            .find(|ptx| ptx.transaction.hash == *tx_hash)
            .map(|ptx| ptx.transaction.clone())
    }

    /// Clear all transactions
    pub async fn clear(&self) {
        let mut accounts = self.accounts.write().await;
        let mut tx_to_account = self.tx_to_account.write().await;
        let mut stats = self.stats.write().await;

        accounts.clear();
        tx_to_account.clear();

        stats.total_transactions = 0;
        stats.pending_transactions = 0;
        stats.queued_transactions = 0;

        info!("Transaction pool cleared");
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_tx(from: &str, nonce: u64, gas_price: u128) -> Transaction {
        let mut hash = [0u8; 32];
        hash[0] = nonce as u8;
        hash[1] = (gas_price >> 8) as u8;

        Transaction {
            hash,
            from: from.to_string(),
            to: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd".to_string(),
            value: 1000,
            gas_price,
            gas_limit: 21_000,
            nonce,
            data: vec![],
        }
    }

    #[tokio::test]
    async fn test_add_transaction() {
        let pool = TransactionPool::new(
            PoolConfig::default(),
            ValidationConfig::default(),
        );

        let tx = create_test_tx("0x1234567890123456789012345678901234567890", 0, 20_000_000_000);
        assert!(pool.add_transaction(tx).await.is_ok());

        let stats = pool.stats().await;
        assert_eq!(stats.total_transactions, 1);
        assert_eq!(stats.total_added, 1);
    }

    #[tokio::test]
    async fn test_duplicate_transaction() {
        let pool = TransactionPool::new(
            PoolConfig::default(),
            ValidationConfig::default(),
        );

        let tx = create_test_tx("0x1234567890123456789012345678901234567890", 0, 20_000_000_000);
        assert!(pool.add_transaction(tx.clone()).await.is_ok());

        let result = pool.add_transaction(tx).await;
        assert!(matches!(result, Err(PoolError::AlreadyExists)));
    }

    #[tokio::test]
    async fn test_nonce_too_low() {
        let pool = TransactionPool::new(
            PoolConfig::default(),
            ValidationConfig::default(),
        );

        let addr = "0x1234567890123456789012345678901234567890";

        // Add transaction with nonce 5
        let tx1 = create_test_tx(addr, 5, 20_000_000_000);
        pool.add_transaction(tx1).await.unwrap();

        // Update account nonce to 6
        pool.update_nonce(addr, 6).await;

        // Try to add transaction with nonce 5 (too low)
        let tx2 = create_test_tx(addr, 5, 20_000_000_000);
        let result = pool.add_transaction(tx2).await;
        eprintln!("Result: {:?}", result);
        assert!(matches!(result, Err(PoolError::NonceTooLow { .. })));
    }

    #[tokio::test]
    async fn test_get_pending_transactions() {
        let pool = TransactionPool::new(
            PoolConfig::default(),
            ValidationConfig::default(),
        );

        let addr = "0x1234567890123456789012345678901234567890";

        // Add transactions with different gas prices
        pool.add_transaction(create_test_tx(addr, 0, 10_000_000_000)).await.unwrap();
        pool.add_transaction(create_test_tx(addr, 1, 30_000_000_000)).await.unwrap();
        pool.add_transaction(create_test_tx(addr, 2, 20_000_000_000)).await.unwrap();

        let pending = pool.get_pending_transactions(10).await;
        assert_eq!(pending.len(), 3);

        // Should be sorted by gas price (highest first)
        assert_eq!(pending[0].gas_price, 30_000_000_000);
        assert_eq!(pending[1].gas_price, 20_000_000_000);
        assert_eq!(pending[2].gas_price, 10_000_000_000);
    }

    #[tokio::test]
    async fn test_remove_transaction() {
        let pool = TransactionPool::new(
            PoolConfig::default(),
            ValidationConfig::default(),
        );

        let tx = create_test_tx("0x1234567890123456789012345678901234567890", 0, 20_000_000_000);
        let tx_hash = tx.hash;

        pool.add_transaction(tx).await.unwrap();
        assert_eq!(pool.stats().await.total_transactions, 1);

        pool.remove_transaction(&tx_hash).await.unwrap();
        assert_eq!(pool.stats().await.total_transactions, 0);
    }

    #[tokio::test]
    async fn test_pool_size_limit() {
        let mut config = PoolConfig::default();
        config.max_pool_size = 2;

        let pool = TransactionPool::new(config, ValidationConfig::default());

        let addr = "0x1234567890123456789012345678901234567890";

        pool.add_transaction(create_test_tx(addr, 0, 20_000_000_000)).await.unwrap();
        pool.add_transaction(create_test_tx(addr, 1, 20_000_000_000)).await.unwrap();

        let result = pool.add_transaction(create_test_tx(addr, 2, 20_000_000_000)).await;
        assert!(matches!(result, Err(PoolError::PoolFull(_))));
    }
}
