//! Network Layer for axionax Core
//!
//! Implements P2P networking using libp2p for:
//! - Block propagation
//! - Transaction propagation
//! - Consensus message distribution
//! - Peer discovery and management

pub mod behaviour;
pub mod config;
pub mod error;
pub mod manager;
pub mod protocol;

pub use config::NetworkConfig;
pub use error::{NetworkError, Result};
pub use manager::NetworkManager;
pub use protocol::{MessageType, NetworkMessage};

#[cfg(test)]
mod tests {
    #[test]
    fn test_network_module() {
        // Basic sanity test (always passes)
    }
}
