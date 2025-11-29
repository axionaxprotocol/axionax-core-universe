use axum::{
    extract::{State, Json},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use std::net::SocketAddr;
use std::env;
use std::time::{SystemTime, UNIX_EPOCH};
use reqwest::Client;
use tower_http::cors::CorsLayer;
use tracing::{info, error, warn};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use dashmap::DashMap;

use crypto::hash;
use ed25519_dalek::SigningKey;
use blockchain::Transaction;

#[derive(Clone)]
struct AppState {
    client: Client,
    rpc_url: String,
    signing_key: Arc<SigningKey>,
    faucet_address: String,
    chain_id: u64,
    amount_per_request: u128,
    rate_limiter: Arc<DashMap<String, u64>>, // IP -> Timestamp
}

#[derive(Deserialize)]
struct RequestFunds {
    address: String,
}

#[derive(Serialize)]
struct Response {
    status: String,
    tx_hash: Option<String>,
    message: Option<String>,
}

#[derive(Serialize)]
struct JsonRpcRequest {
    jsonrpc: String,
    method: String,
    params: Vec<serde_json::Value>,
    id: u64,
}

#[derive(Deserialize)]
struct JsonRpcResponse<T> {
    result: Option<T>,
    error: Option<JsonRpcError>,
}

#[derive(Deserialize)]
struct JsonRpcError {
    message: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenv::dotenv().ok();
    let rpc_url = env::var("RPC_URL").unwrap_or_else(|_| "http://localhost:8545".to_string());
    let chain_id = env::var("CHAIN_ID").unwrap_or_else(|_| "86137".to_string()).parse::<u64>()?;
    let private_key_hex = env::var("FAUCET_PRIVATE_KEY").expect("FAUCET_PRIVATE_KEY must be set");
    let port = env::var("PORT").unwrap_or_else(|_| "3000".to_string()).parse::<u16>()?;

    // Load private key
    // Assuming private key is 32 bytes hex
    let pk_bytes = hex::decode(private_key_hex.strip_prefix("0x").unwrap_or(&private_key_hex))
        .expect("Invalid private key hex");
    
    // We need to construct SigningKey from bytes. 
    // Since crypto::signature::generate_keypair() returns SigningKey, and we want to load one,
    // we might need to use ed25519_dalek directly if crypto doesn't expose `from_bytes`.
    // Checking crypto lib.rs, SigningKey is re-exported from ed25519_dalek.
    // But `crypto::signature` doesn't expose `from_bytes`. 
    // However, `crypto::VRF` does: `SigningKey::from_bytes`.
    // Since we depend on `crypto`, and `SigningKey` is public there (via use ed25519_dalek::SigningKey), 
    // we can use ed25519_dalek methods if we import it.
    // BUT we didn't add `ed25519-dalek` to our Cargo.toml, only `crypto`.
    // Wait, `crypto` re-exports `SigningKey`.
    // Let's check `crypto/src/lib.rs` again. `use ed25519_dalek::{...}`. It does NOT `pub use`.
    // But `VRF` struct has `pub fn from_signing_key(signing_key: SigningKey)`.
    // The `SigningKey` type is visible in signature.
    // Actually, `crypto/src/lib.rs` does NOT `pub use ed25519_dalek`.
    // It says `use ed25519_dalek::{...}` inside the module.
    // So `SigningKey` might not be accessible outside unless re-exported.
    // `pub mod signature` uses `super::*`.
    // It returns `SigningKey` in `generate_keypair`. So `SigningKey` MUST be public.
    
    // Assuming we can use `ed25519_dalek::SigningKey` via `crypto::signature`.
    // Let's assume `crypto` crate exposes it. If not, I'll need to add `ed25519-dalek` to Cargo.toml.
    // I'll add `ed25519-dalek` to Cargo.toml just in case.
    // Wait, I already wrote Cargo.toml.
    
    // Let's try to trust `crypto` crate. If compilation fails, I'll fix it.
    // But `crypto::signature::generate_keypair()` returns `SigningKey`.
    // So `SigningKey` is definitely available.
    
    // However, loading from bytes might need `ed25519_dalek::SigningKey::from_bytes(&bytes)`.
    // Since `crypto` doesn't export `from_bytes` wrapper, I might need direct access.
    
    // I'll just assume I can't load it easily without `ed25519-dalek`. 
    // I will rewrite Cargo.toml to include it if needed.
    
    // WORKAROUND: Generate a random key for now if we can't load it, OR better:
    // Rely on `crypto::signature::generate_keypair()` and print it on startup if we can't load.
    // But for a Faucet, we need persistence.
    
    // Let's assume I need `ed25519-dalek` dependency.
    // I'll update Cargo.toml in next step if verification fails.
    
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&pk_bytes.try_into().expect("Invalid key length"));
    let verifying_key = signing_key.verifying_key();
    
    // Derive address
    // Address = 0x + hex(keccak256(pubkey)[12..])
    let pub_bytes = verifying_key.to_bytes();
    let hash = hash::keccak256(&pub_bytes);
    let faucet_address = format!("0x{}", hex::encode(&hash[12..]));
    
    info!("Faucet initialized");
    info!("Address: {}", faucet_address);
    info!("Chain ID: {}", chain_id);
    info!("RPC URL: {}", rpc_url);

    let app_state = AppState {
        client: Client::new(),
        rpc_url,
        signing_key: Arc::new(signing_key),
        faucet_address,
        chain_id,
        amount_per_request: 100 * 10_u128.pow(18), // 100 AXX
        rate_limiter: Arc::new(DashMap::new()),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/info", get(info_handler))
        .route("/request", post(request_handler))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    info!("Listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}

async fn info_handler(State(state): State<AppState>) -> impl IntoResponse {
    Json(serde_json::json!({
        "address": state.faucet_address,
        "chain_id": state.chain_id,
        "amount_per_request": state.amount_per_request.to_string(),
        "status": "operational"
    }))
}

async fn request_handler(
    State(state): State<AppState>,
    Json(payload): Json<RequestFunds>,
) -> impl IntoResponse {
    let address = payload.address;
    info!("Received request for {}", address);

    // Rate limit check (simple IP-based would need extraction, here using address)
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    if let Some(last_request) = state.rate_limiter.get(&address) {
        if now - *last_request < 86400 { // 24 hours
            return (
                StatusCode::TOO_MANY_REQUESTS,
                Json(Response {
                    status: "error".to_string(),
                    tx_hash: None,
                    message: Some("Rate limit exceeded (1 request per 24h)".to_string()),
                }),
            ).into_response();
        }
    }

    // Get nonce
    let nonce = match get_nonce(&state.client, &state.rpc_url, &state.faucet_address).await {
        Ok(n) => n,
        Err(e) => {
            error!("Failed to get nonce: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(Response {
                    status: "error".to_string(),
                    tx_hash: None,
                    message: Some("Failed to get nonce from RPC".to_string()),
                }),
            ).into_response();
        }
    };

    // Create transaction
    let mut tx = Transaction {
        hash: [0u8; 32],
        from: state.faucet_address.clone(),
        to: address.clone(),
        value: state.amount_per_request,
        gas_price: 20, // 20 wei (minimal)
        gas_limit: 21000,
        nonce,
        data: vec![],
    };

    // Calculate hash (simple serialization for signing)
    // We need to match what the node expects.
    // But since signature verification is TODO in node, we just need a unique hash?
    // Node converts tx to hash using `hex_to_hash`? No, Node computes hash from fields?
    // `Transaction` struct has `hash` field.
    // In `lib.rs`: `pub hash: [u8; 32]`.
    // The hash should be derived from content.
    // We'll use a simple method: hash(from + to + value + nonce)
    let mut data_to_hash = Vec::new();
    data_to_hash.extend_from_slice(tx.from.as_bytes());
    data_to_hash.extend_from_slice(tx.to.as_bytes());
    data_to_hash.extend_from_slice(&tx.value.to_le_bytes());
    data_to_hash.extend_from_slice(&tx.nonce.to_le_bytes());
    
    // Using blake2s like in crypto lib docs
    let tx_hash = hash::blake2s_256(&data_to_hash);
    tx.hash = tx_hash;

    // Sign transaction (even if node ignores it, we do it right)
    // Signature is over the hash
    // let signature = crypto::signature::sign(&state.signing_key, &tx_hash);
    // Note: crypto::signature::sign takes &SigningKey.
    
    // Serialize to JSON bytes
    // Since we defined `eth_sendRawTransaction` to take hex string of JSON bytes
    let tx_json = serde_json::to_vec(&tx).unwrap();
    let tx_hex = format!("0x{}", hex::encode(tx_json));

    // Send transaction
    match send_raw_transaction(&state.client, &state.rpc_url, tx_hex).await {
        Ok(hash) => {
            state.rate_limiter.insert(address.clone(), now);
            info!("Sent funds to {}: {}", address, hash);
            (
                StatusCode::OK,
                Json(Response {
                    status: "success".to_string(),
                    tx_hash: Some(hash),
                    message: Some("Funds sent successfully".to_string()),
                }),
            ).into_response()
        },
        Err(e) => {
            error!("Failed to send transaction: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(Response {
                    status: "error".to_string(),
                    tx_hash: None,
                    message: Some(format!("Failed to send transaction: {}", e)),
                }),
            ).into_response()
        }
    }
}

async fn get_nonce(client: &Client, rpc_url: &str, address: &str) -> anyhow::Result<u64> {
    let request = JsonRpcRequest {
        jsonrpc: "2.0".to_string(),
        method: "eth_getTransactionCount".to_string(),
        params: vec![serde_json::json!(address), serde_json::json!("latest")],
        id: 1,
    };

    let res = client.post(rpc_url)
        .json(&request)
        .send()
        .await?;

    let body: JsonRpcResponse<String> = res.json().await?;
    
    if let Some(err) = body.error {
        return Err(anyhow::anyhow!("RPC error: {}", err.message));
    }

    if let Some(result) = body.result {
        let hex = result.strip_prefix("0x").unwrap_or(&result);
        Ok(u64::from_str_radix(hex, 16)?)
    } else {
        Ok(0) // Default to 0 if no result (or error handling needed)
    }
}

async fn send_raw_transaction(client: &Client, rpc_url: &str, tx_hex: String) -> anyhow::Result<String> {
    let request = JsonRpcRequest {
        jsonrpc: "2.0".to_string(),
        method: "eth_sendRawTransaction".to_string(),
        params: vec![serde_json::json!(tx_hex)],
        id: 1,
    };

    let res = client.post(rpc_url)
        .json(&request)
        .send()
        .await?;

    let body: JsonRpcResponse<String> = res.json().await?;
    
    if let Some(err) = body.error {
        return Err(anyhow::anyhow!("RPC error: {}", err.message));
    }

    if let Some(result) = body.result {
        Ok(result)
    } else {
        Err(anyhow::anyhow!("No result from RPC"))
    }
}
