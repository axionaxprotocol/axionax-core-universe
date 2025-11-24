//! RPC Middleware for Security and Rate Limiting
//!
//! Provides rate limiting, request validation, and security checks for RPC endpoints

use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;
use tracing::{debug, warn};

/// Rate limiter configuration
#[derive(Debug, Clone)]
pub struct RateLimitConfig {
    /// Maximum requests per window
    pub max_requests: u32,
    /// Time window duration
    pub window: Duration,
    /// Burst allowance (extra requests allowed in short bursts)
    pub burst: u32,
}

impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            max_requests: 100,
            window: Duration::from_secs(60),
            burst: 20,
        }
    }
}

/// Rate limit entry for tracking requests
#[derive(Debug, Clone)]
struct RateLimitEntry {
    requests: u32,
    window_start: Instant,
    burst_tokens: u32,
}

/// Rate limiter for controlling request frequency
pub struct RateLimiter {
    entries: Arc<RwLock<HashMap<IpAddr, RateLimitEntry>>>,
    config: RateLimitConfig,
}

impl RateLimiter {
    /// Create a new rate limiter
    pub fn new(config: RateLimitConfig) -> Self {
        let limiter = Self {
            entries: Arc::new(RwLock::new(HashMap::new())),
            config,
        };

        // Start cleanup task
        limiter.start_cleanup_task();

        limiter
    }

    /// Check if a request from an IP should be allowed
    pub async fn check(&self, ip: IpAddr) -> Result<(), String> {
        let mut entries = self.entries.write().await;
        let now = Instant::now();

        let entry = entries.entry(ip).or_insert_with(|| RateLimitEntry {
            requests: 0,
            window_start: now,
            burst_tokens: self.config.burst,
        });

        // Check if window has expired
        if now.duration_since(entry.window_start) >= self.config.window {
            // Reset window
            entry.requests = 0;
            entry.window_start = now;
            entry.burst_tokens = self.config.burst;
        }

        // Check rate limit
        if entry.requests >= self.config.max_requests {
            // Try to use burst token
            if entry.burst_tokens > 0 {
                entry.burst_tokens -= 1;
                entry.requests += 1;
                debug!("Request allowed using burst token for {}", ip);
                return Ok(());
            }

            warn!("Rate limit exceeded for IP: {}", ip);
            return Err(format!(
                "Rate limit exceeded. Max {} requests per {} seconds",
                self.config.max_requests,
                self.config.window.as_secs()
            ));
        }

        entry.requests += 1;
        Ok(())
    }

    /// Get current request count for an IP
    pub async fn get_count(&self, ip: IpAddr) -> u32 {
        let entries = self.entries.read().await;
        entries.get(&ip).map(|e| e.requests).unwrap_or(0)
    }

    /// Start background task to clean up old entries
    fn start_cleanup_task(&self) {
        let entries = self.entries.clone();
        let window = self.config.window;

        tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(300)); // Cleanup every 5 minutes

            loop {
                interval.tick().await;

                let mut entries_guard = entries.write().await;
                let now = Instant::now();

                // Remove expired entries
                entries_guard.retain(|ip, entry| {
                    let keep = now.duration_since(entry.window_start) < window * 2;
                    if !keep {
                        debug!("Cleaned up rate limit entry for {}", ip);
                    }
                    keep
                });
            }
        });
    }
}

/// Request size validator
pub struct RequestValidator {
    max_batch_size: usize,
    max_request_size: usize,
}

impl RequestValidator {
    /// Create a new request validator
    pub fn new(max_batch_size: usize, max_request_size: usize) -> Self {
        Self {
            max_batch_size,
            max_request_size,
        }
    }

    /// Validate request size
    pub fn validate_size(&self, size: usize) -> Result<(), String> {
        if size > self.max_request_size {
            return Err(format!(
                "Request too large: {} bytes (max: {})",
                size, self.max_request_size
            ));
        }
        Ok(())
    }

    /// Validate batch request size
    pub fn validate_batch(&self, batch_size: usize) -> Result<(), String> {
        if batch_size > self.max_batch_size {
            return Err(format!(
                "Batch too large: {} requests (max: {})",
                batch_size, self.max_batch_size
            ));
        }
        Ok(())
    }
}

impl Default for RequestValidator {
    fn default() -> Self {
        Self::new(
            50,        // Max 50 requests in a batch
            1_048_576, // Max 1MB request size
        )
    }
}

/// CORS configuration
#[derive(Debug, Clone)]
pub struct CorsConfig {
    /// Allowed origins (e.g., ["https://app.axionax.org"])
    pub allowed_origins: Vec<String>,
    /// Allow all origins (use only for development)
    pub allow_all: bool,
    /// Allowed methods
    pub allowed_methods: Vec<String>,
    /// Allowed headers
    pub allowed_headers: Vec<String>,
    /// Max age for preflight cache (seconds)
    pub max_age: u64,
}

impl CorsConfig {
    /// Create development CORS config (allows all origins)
    pub fn dev() -> Self {
        Self {
            allowed_origins: vec![],
            allow_all: true,
            allowed_methods: vec!["GET".to_string(), "POST".to_string(), "OPTIONS".to_string()],
            allowed_headers: vec!["Content-Type".to_string(), "Authorization".to_string()],
            max_age: 3600,
        }
    }

    /// Create production CORS config
    pub fn production(allowed_origins: Vec<String>) -> Self {
        Self {
            allowed_origins,
            allow_all: false,
            allowed_methods: vec!["POST".to_string(), "OPTIONS".to_string()],
            allowed_headers: vec!["Content-Type".to_string()],
            max_age: 86400, // 24 hours
        }
    }

    /// Check if origin is allowed
    pub fn is_origin_allowed(&self, origin: &str) -> bool {
        if self.allow_all {
            return true;
        }

        self.allowed_origins.iter().any(|o| o == origin)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;

    #[tokio::test]
    async fn test_rate_limiter_allows_requests() {
        let config = RateLimitConfig {
            max_requests: 10,
            window: Duration::from_secs(60),
            burst: 5,
        };

        let limiter = RateLimiter::new(config);
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));

        // First 10 requests should be allowed
        for _ in 0..10 {
            assert!(limiter.check(ip).await.is_ok());
        }

        // Next 5 burst requests should be allowed
        for _ in 0..5 {
            assert!(limiter.check(ip).await.is_ok());
        }

        // 16th request should be denied
        assert!(limiter.check(ip).await.is_err());
    }

    #[tokio::test]
    async fn test_rate_limiter_window_reset() {
        let config = RateLimitConfig {
            max_requests: 5,
            window: Duration::from_millis(100),
            burst: 0,
        };

        let limiter = RateLimiter::new(config);
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));

        // Use up the limit
        for _ in 0..5 {
            assert!(limiter.check(ip).await.is_ok());
        }

        // Should be denied
        assert!(limiter.check(ip).await.is_err());

        // Wait for window to reset
        tokio::time::sleep(Duration::from_millis(150)).await;

        // Should be allowed again
        assert!(limiter.check(ip).await.is_ok());
    }

    #[tokio::test]
    async fn test_rate_limiter_multiple_ips() {
        let config = RateLimitConfig {
            max_requests: 5,
            window: Duration::from_secs(60),
            burst: 0,
        };

        let limiter = RateLimiter::new(config);
        let ip1 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        let ip2 = IpAddr::V4(Ipv4Addr::new(192, 168, 1, 1));

        // IP1 uses up limit
        for _ in 0..5 {
            assert!(limiter.check(ip1).await.is_ok());
        }
        assert!(limiter.check(ip1).await.is_err());

        // IP2 should still have full limit
        for _ in 0..5 {
            assert!(limiter.check(ip2).await.is_ok());
        }
    }

    #[test]
    fn test_request_validator_size() {
        let validator = RequestValidator::new(10, 1000);

        assert!(validator.validate_size(500).is_ok());
        assert!(validator.validate_size(1000).is_ok());
        assert!(validator.validate_size(1001).is_err());
    }

    #[test]
    fn test_request_validator_batch() {
        let validator = RequestValidator::new(10, 1000);

        assert!(validator.validate_batch(5).is_ok());
        assert!(validator.validate_batch(10).is_ok());
        assert!(validator.validate_batch(11).is_err());
    }

    #[test]
    fn test_cors_dev_config() {
        let cors = CorsConfig::dev();

        assert!(cors.allow_all);
        assert!(cors.is_origin_allowed("https://evil.com"));
        assert!(cors.is_origin_allowed("http://localhost:3000"));
    }

    #[test]
    fn test_cors_production_config() {
        let cors = CorsConfig::production(vec![
            "https://app.axionax.org".to_string(),
            "https://wallet.axionax.org".to_string(),
        ]);

        assert!(!cors.allow_all);
        assert!(cors.is_origin_allowed("https://app.axionax.org"));
        assert!(!cors.is_origin_allowed("https://evil.com"));
    }
}
