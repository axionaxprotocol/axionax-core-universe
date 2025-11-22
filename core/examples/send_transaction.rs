// Example: Create and send a transaction using AxionAx SDK
use axionax_blockchain::{Blockchain, Transaction};
use axionax_crypto::{generate_keypair, sign_message};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("AxionAx Transaction Example\n");

    // Initialize blockchain
    let mut blockchain = Blockchain::new();
    println!("✓ Blockchain initialized");

    // Generate keypair
    let (private_key, public_key) = generate_keypair();
    println!("✓ Keypair generated");
    println!("  Public key: {}", hex::encode(&public_key));

    // Create transaction
    let tx = Transaction {
        from: hex::encode(&public_key),
        to: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb".to_string(),
        value: 1_000_000_000_000_000_000, // 1 AXX
        nonce: 0,
        gas_limit: 21000,
        gas_price: 1_000_000_000, // 1 Gwei
        data: vec![],
        signature: None,
    };

    // Sign transaction
    let tx_bytes = tx.to_bytes();
    let signature = sign_message(&private_key, &tx_bytes)?;
    
    let signed_tx = Transaction {
        signature: Some(signature),
        ..tx
    };

    println!("✓ Transaction signed");
    println!("  Hash: {}", signed_tx.hash());

    // Add to pending transactions
    blockchain.add_pending_transaction(signed_tx)?;
    println!("✓ Transaction added to mempool");

    Ok(())
}
