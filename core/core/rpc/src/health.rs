//! Health Check and Status Endpoints
//!
//! Provides health monitoring and node status information

use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use state::StateDB;

/// Health status response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthStatus {
    /// Overall health status
    pub status: String,
    /// Timestamp of the check
    pub timestamp: u64,
    /// Individual component health
    pub components: ComponentsHealth,
}

/// Individual component health statuses
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComponentsHealth {
    pub database: ComponentStatus,
    pub sync: ComponentStatus,
    pub network: ComponentStatus,
}

/// Individual component status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComponentStatus {
    pub status: String,
    pub message: Option<String>,
}

impl ComponentStatus {
    pub fn healthy() -> Self {
        Self {
            status: "healthy".to_string(),
            message: None,
        }
    }

    pub fn unhealthy(message: String) -> Self {
        Self {
            status: "unhealthy".to_string(),
            message: Some(message),
        }
    }
}

/// Node status information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeStatus {
    pub chain_id: u64,
    pub network: String,
    pub version: String,
    pub sync_status: SyncStatus,
    pub peer_count: usize,
}

/// Sync status information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub syncing: bool,
    pub current_block: u64,
    pub highest_block: u64,
    pub starting_block: u64,
}

/// Health checker
pub struct HealthChecker {
    state: Arc<StateDB>,
}

impl HealthChecker {
    /// Create a new health checker
    pub fn new(state: Arc<StateDB>) -> Self {
        Self { state }
    }

    /// Check overall health
    pub async fn check_health(&self) -> HealthStatus {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let db_health = self.check_database().await;
        let sync_health = self.check_sync().await;
        let network_health = self.check_network().await;

        let overall_status = if db_health.status == "healthy"
            && sync_health.status == "healthy"
            && network_health.status == "healthy"
        {
            "healthy".to_string()
        } else {
            "unhealthy".to_string()
        };

        HealthStatus {
            status: overall_status,
            timestamp,
            components: ComponentsHealth {
                database: db_health,
                sync: sync_health,
                network: network_health,
            },
        }
    }

    /// Check database health
    async fn check_database(&self) -> ComponentStatus {
        match self.state.get_chain_height() {
            Ok(_) => ComponentStatus::healthy(),
            Err(e) => ComponentStatus::unhealthy(format!("Database error: {}", e)),
        }
    }

    /// Check sync status health
    async fn check_sync(&self) -> ComponentStatus {
        // TODO: Implement actual sync checking logic
        // For now, just return healthy
        ComponentStatus::healthy()
    }

    /// Check network health
    async fn check_network(&self) -> ComponentStatus {
        // TODO: Implement actual network checking logic
        // For now, just return healthy
        ComponentStatus::healthy()
    }

    /// Get node status
    pub async fn get_node_status(&self, chain_id: u64) -> NodeStatus {
        let current_block = self.state.get_chain_height().unwrap_or(0);

        NodeStatus {
            chain_id,
            network: if chain_id == 31337 {
                "dev".to_string()
            } else if chain_id == 86137 {
                "testnet".to_string()
            } else {
                "mainnet".to_string()
            },
            version: env!("CARGO_PKG_VERSION").to_string(),
            sync_status: SyncStatus {
                syncing: false, // TODO: Implement actual sync status
                current_block,
                highest_block: current_block,
                starting_block: 0,
            },
            peer_count: 0, // TODO: Get actual peer count
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_state() -> Arc<StateDB> {
        let temp_dir = TempDir::new().unwrap();
        Arc::new(StateDB::open(temp_dir.path()).unwrap())
    }

    #[tokio::test]
    async fn test_health_check_healthy() {
        let state = create_test_state();
        let checker = HealthChecker::new(state);

        let health = checker.check_health().await;
        assert_eq!(health.status, "healthy");
        assert_eq!(health.components.database.status, "healthy");
    }

    #[tokio::test]
    async fn test_node_status() {
        let state = create_test_state();
        let checker = HealthChecker::new(state);

        let status = checker.get_node_status(86137).await;
        assert_eq!(status.chain_id, 86137);
        assert_eq!(status.network, "testnet");
        assert_eq!(status.sync_status.current_block, 0);
    }

    #[test]
    fn test_component_status() {
        let healthy = ComponentStatus::healthy();
        assert_eq!(healthy.status, "healthy");
        assert!(healthy.message.is_none());

        let unhealthy = ComponentStatus::unhealthy("test error".to_string());
        assert_eq!(unhealthy.status, "unhealthy");
        assert_eq!(unhealthy.message.unwrap(), "test error");
    }
}
