#!/bin/bash
# Genesis Launch Coordinator Script
# Coordinates validator nodes for genesis launch

set -e

# Configuration
GENESIS_FILE="genesis.json"
VALIDATORS_FILE="validators-active.json"
LAUNCH_TIME=""  # Will be set
BOOTSTRAP_NODE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check genesis file exists
    if [ ! -f "$GENESIS_FILE" ]; then
        log_error "Genesis file not found: $GENESIS_FILE"
        exit 1
    fi
    
    # Check validators file exists
    if [ ! -f "$VALIDATORS_FILE" ]; then
        log_error "Validators file not found: $VALIDATORS_FILE"
        exit 1
    fi
    
    # Check jq installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Install with: sudo apt install jq"
        exit 1
    fi
    
    # Check ssh configured
    if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
        log_warning "No SSH key found. Validators may require password authentication."
    fi
    
    log_success "Prerequisites check passed"
}

# Calculate genesis hash
calculate_genesis_hash() {
    log_info "Calculating genesis hash..."
    GENESIS_HASH=$(sha256sum "$GENESIS_FILE" | awk '{print $1}')
    log_success "Genesis Hash: 0x$GENESIS_HASH"
    echo "$GENESIS_HASH" > genesis-hash.txt
}

# Distribute genesis to validators
distribute_genesis() {
    log_info "Distributing genesis file to validators..."
    
    # Read validator IPs
    VALIDATOR_IPS=$(jq -r '.[].ip // empty' "$VALIDATORS_FILE")
    
    if [ -z "$VALIDATOR_IPS" ]; then
        log_warning "No validator IPs found in $VALIDATORS_FILE"
        log_info "You must manually distribute genesis.json to validators"
        return
    fi
    
    for ip in $VALIDATOR_IPS; do
        log_info "Uploading genesis to validator: $ip"
        
        # Try to upload via SCP
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
            "$GENESIS_FILE" "root@$ip:~/.axionax/config/genesis.json" 2>/dev/null; then
            log_success "Uploaded to $ip"
        else
            log_warning "Failed to upload to $ip (manual distribution required)"
        fi
    done
}

# Verify all validators ready
check_validator_readiness() {
    log_info "Checking validator readiness..."
    
    VALIDATOR_IPS=$(jq -r '.[].ip // empty' "$VALIDATORS_FILE")
    READY_COUNT=0
    TOTAL_COUNT=$(echo "$VALIDATOR_IPS" | wc -w)
    
    for ip in $VALIDATOR_IPS; do
        log_info "Checking validator: $ip"
        
        # Check SSH connectivity
        if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
            "root@$ip" "exit" 2>/dev/null; then
            log_error "Cannot connect to $ip"
            continue
        fi
        
        # Check genesis file present
        if ! ssh "root@$ip" "test -f ~/.axionax/config/genesis.json" 2>/dev/null; then
            log_error "$ip: genesis.json not found"
            continue
        fi
        
        # Verify genesis hash
        REMOTE_HASH=$(ssh "root@$ip" "sha256sum ~/.axionax/config/genesis.json | awk '{print \$1}'" 2>/dev/null)
        if [ "$REMOTE_HASH" != "$GENESIS_HASH" ]; then
            log_error "$ip: genesis hash mismatch!"
            log_error "  Expected: $GENESIS_HASH"
            log_error "  Got: $REMOTE_HASH"
            continue
        fi
        
        # Check node initialized
        if ! ssh "root@$ip" "test -d ~/.axionax/data" 2>/dev/null; then
            log_warning "$ip: node not initialized (run: axionax-core init)"
            continue
        fi
        
        log_success "$ip is ready"
        READY_COUNT=$((READY_COUNT + 1))
    done
    
    echo ""
    log_info "Validator Readiness: $READY_COUNT / $TOTAL_COUNT"
    
    if [ "$READY_COUNT" -lt 3 ]; then
        log_error "Less than 3 validators ready. Cannot launch network."
        return 1
    elif [ "$READY_COUNT" -lt "$TOTAL_COUNT" ]; then
        log_warning "Not all validators ready. Launch may proceed but with reduced decentralization."
        read -p "Continue with launch? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Start coordinator node (bootstrap)
start_coordinator_node() {
    log_info "Starting coordinator node (bootstrap)..."
    
    # Start local validator
    sudo systemctl start axionax-validator
    
    # Wait for node to be ready
    sleep 10
    
    # Get enode URL
    log_info "Fetching enode URL..."
    ENODE=$(curl -s -X POST http://127.0.0.1:8545 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
        | jq -r '.result.enode' 2>/dev/null)
    
    if [ -z "$ENODE" ] || [ "$ENODE" == "null" ]; then
        log_error "Failed to get enode URL"
        log_info "Check node logs: journalctl -u axionax-validator -f"
        return 1
    fi
    
    BOOTSTRAP_NODE="$ENODE"
    log_success "Bootstrap node started"
    log_info "Enode: $BOOTSTRAP_NODE"
    
    # Save for validators
    echo "$BOOTSTRAP_NODE" > bootstrap-node.txt
}

# Coordinate validator launch
launch_validators() {
    log_info "Launching validator nodes..."
    
    if [ -z "$BOOTSTRAP_NODE" ]; then
        log_error "Bootstrap node not started"
        return 1
    fi
    
    VALIDATOR_IPS=$(jq -r '.[].ip // empty' "$VALIDATORS_FILE")
    
    for ip in $VALIDATOR_IPS; do
        log_info "Starting validator: $ip"
        
        # Update bootstrap node
        ssh "root@$ip" "echo '$BOOTSTRAP_NODE' > /tmp/bootstrap-node.txt" 2>/dev/null || true
        
        # Start validator service
        if ssh "root@$ip" "sudo systemctl start axionax-validator" 2>/dev/null; then
            log_success "Started validator: $ip"
        else
            log_error "Failed to start validator: $ip"
        fi
        
        # Small delay between starts
        sleep 2
    done
    
    log_success "All validators launched"
}

# Monitor network health
monitor_network() {
    log_info "Monitoring network health..."
    
    local duration=300  # Monitor for 5 minutes
    local interval=10   # Check every 10 seconds
    local elapsed=0
    
    while [ $elapsed -lt $duration ]; do
        # Get current block
        BLOCK=$(curl -s -X POST http://127.0.0.1:8545 \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            | jq -r '.result' 2>/dev/null)
        
        if [ -n "$BLOCK" ] && [ "$BLOCK" != "null" ]; then
            BLOCK_NUM=$((16#${BLOCK#0x}))
            log_info "Current Block: $BLOCK_NUM"
        else
            log_warning "Unable to fetch block number"
        fi
        
        # Get peer count
        PEERS=$(curl -s -X POST http://127.0.0.1:8545 \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            | jq -r '.result' 2>/dev/null)
        
        if [ -n "$PEERS" ] && [ "$PEERS" != "null" ]; then
            PEER_NUM=$((16#${PEERS#0x}))
            log_info "Peer Count: $PEER_NUM"
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_success "Monitoring complete. Check Grafana dashboard for detailed metrics."
}

# Main launch sequence
main() {
    echo "============================================================"
    echo "  axionax Genesis Launch Coordinator"
    echo "============================================================"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Calculate genesis hash
    calculate_genesis_hash
    echo ""
    
    # Optional: Distribute genesis
    read -p "Distribute genesis file to validators? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        distribute_genesis
        echo ""
    fi
    
    # Check validator readiness
    if ! check_validator_readiness; then
        log_error "Validator readiness check failed. Aborting launch."
        exit 1
    fi
    echo ""
    
    # Confirm launch
    echo "============================================================"
    echo "  READY TO LAUNCH"
    echo "============================================================"
    echo "Genesis Hash: 0x$GENESIS_HASH"
    echo ""
    read -p "Proceed with genesis launch? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Launch aborted by user"
        exit 0
    fi
    
    # Launch sequence
    echo "============================================================"
    echo "  LAUNCH SEQUENCE"
    echo "============================================================"
    echo ""
    
    # Start coordinator
    log_info "STEP 1: Starting coordinator node..."
    if ! start_coordinator_node; then
        log_error "Failed to start coordinator node"
        exit 1
    fi
    echo ""
    
    # Wait a bit
    log_info "Waiting 15 seconds before launching validators..."
    sleep 15
    echo ""
    
    # Launch validators
    log_info "STEP 2: Launching validator nodes..."
    launch_validators
    echo ""
    
    # Wait for consensus
    log_info "Waiting 30 seconds for consensus to form..."
    sleep 30
    echo ""
    
    # Monitor
    log_info "STEP 3: Monitoring network..."
    monitor_network
    echo ""
    
    # Final status
    echo "============================================================"
    echo "  LAUNCH COMPLETE"
    echo "============================================================"
    echo ""
    log_success "axionax Testnet genesis launch completed!"
    log_info "Genesis Hash: 0x$GENESIS_HASH"
    log_info "Bootstrap Node: $BOOTSTRAP_NODE"
    echo ""
    log_info "Next Steps:"
    echo "  1. Monitor Grafana dashboard"
    echo "  2. Enable public RPC endpoints"
    echo "  3. Start block explorer"
    echo "  4. Activate faucet"
    echo "  5. Announce launch to community"
    echo ""
    log_info "For support: validators@axionax.org"
}

# Run main
main
