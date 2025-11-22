// Example: Run a local AxionAx node
use axionax_node::{Node, NodeConfig};
use axionax_rpc::RpcServer;
use std::sync::Arc;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting AxionAx Node...\n");

    // Load configuration
    let config = NodeConfig {
        chain_id: 86137, // Testnet
        rpc_port: 8545,
        p2p_port: 30303,
        data_dir: "./data".into(),
        enable_mining: true,
        ..Default::default()
    };

    println!("Configuration:");
    println!("  Chain ID: {}", config.chain_id);
    println!("  RPC Port: {}", config.rpc_port);
    println!("  P2P Port: {}", config.p2p_port);
    println!("");

    // Start node
    let node = Arc::new(Node::new(config).await?);
    println!("✓ Node initialized");

    // Start RPC server
    let rpc_server = RpcServer::new(node.clone(), "127.0.0.1:8545".parse()?);
    println!("✓ RPC server starting on http://127.0.0.1:8545");

    // Run the server
    rpc_server.run().await?;

    Ok(())
}
