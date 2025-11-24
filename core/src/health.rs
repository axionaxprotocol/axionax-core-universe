use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::time::SystemTime;

#[derive(Serialize, Deserialize)]
pub struct HealthStatus {
    pub status: String,
    pub timestamp: u64,
    pub version: String,
    pub chain_id: u64,
    pub checks: HealthChecks,
}

#[derive(Serialize, Deserialize)]
pub struct HealthChecks {
    pub database: bool,
    pub p2p: bool,
    pub consensus: bool,
    pub rpc: bool,
}

/// Health check endpoint handler
pub async fn health_check() -> impl IntoResponse {
    let timestamp = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let health = HealthStatus {
        status: "healthy".to_string(),
        timestamp,
        version: env!("CARGO_PKG_VERSION").to_string(),
        chain_id: 86137, // Testnet chain ID
        checks: HealthChecks {
            database: check_database(),
            p2p: check_p2p(),
            consensus: check_consensus(),
            rpc: true, // If we're responding, RPC is working
        },
    };

    // Return 200 OK if all checks pass, 503 Service Unavailable otherwise
    let all_healthy = health.checks.database 
        && health.checks.p2p 
        && health.checks.consensus 
        && health.checks.rpc;

    if all_healthy {
        (StatusCode::OK, Json(health))
    } else {
        (StatusCode::SERVICE_UNAVAILABLE, Json(health))
    }
}

/// Liveness probe - simple check that the service is running
pub async fn liveness() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}

/// Readiness probe - check if the service is ready to accept traffic
pub async fn readiness() -> impl IntoResponse {
    // Check critical dependencies
    let ready = check_database() && check_consensus();

    if ready {
        (StatusCode::OK, "READY")
    } else {
        (StatusCode::SERVICE_UNAVAILABLE, "NOT_READY")
    }
}

/// Check database connectivity
fn check_database() -> bool {
    // Database health is checked through state operations
    // If the service is running, database is assumed healthy
    // More sophisticated checks can query actual DB metrics
    true
}

/// Check P2P network health
fn check_p2p() -> bool {
    // P2P health would check:
    // - Active peer connections (>= min_peers)
    // - Network reachability
    // - Message propagation latency
    // For now, return true if service is running
    true
}

/// Check consensus participation
fn check_consensus() -> bool {
    // Consensus health would check:
    // - Sync status (not lagging behind)
    // - Validator participation (if validator node)
    // - Recent block production
    // For now, return true if service is running
    true
}

/// Create health check router
pub fn health_router() -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/health/live", get(liveness))
        .route("/health/ready", get(readiness))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_liveness() {
        let (status, body) = liveness().await.into_response().into_parts();
        assert_eq!(status, StatusCode::OK);
    }

    #[tokio::test]
    async fn test_health_check() {
        let (status, _) = health_check().await.into_response().into_parts();
        assert_eq!(status, StatusCode::OK);
    }
}
