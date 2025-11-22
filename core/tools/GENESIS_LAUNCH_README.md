# Genesis Launch Toolkit
**axionax Testnet Genesis Ceremony Tools**

## 📁 Files in This Directory

### Scripts
- `create_genesis.py` - Genesis file generator
- `verify_genesis.py` - Genesis file validator
- `launch_genesis.sh` - Launch coordinator (bash)

### Configuration Templates
- `validators-example.json` - Example validator configuration
- `allocations-example.json` - Example token allocations
- `genesis.json` - Generated genesis file (if created)

### Generated Files
- `genesis-hash.txt` - SHA256 hash of genesis.json
- `bootstrap-node.txt` - Bootstrap enode URL

---

## 🚀 Quick Start Guide

### Step 1: Prepare Validator Information

Create `validators-active.json` with real validator data:

```json
[
  {
    "name": "Validator-SG-01",
    "address": "0x1234567890abcdef1234567890abcdef12345678",
    "stake": "50000000000000000000000",
    "commission": 0.10,
    "enode": "enode://PUBKEY@IP:30303",
    "location": "Singapore",
    "operator": "Validator Name",
    "ip": "123.456.789.012"
  }
]
```

**Required Fields**:
- `name`: Validator display name
- `address`: Ethereum-style address (0x...)
- `stake`: Initial stake in wei (50K AXX = "50000000000000000000000")
- `commission`: Commission rate (0.10 = 10%)
- `enode`: P2P enode URL
- `ip`: VPS IP address (for automated deployment)

### Step 2: Create Genesis File

```bash
# Using example files
python3 create_genesis.py validators-example.json allocations-example.json

# Using real validator data
python3 create_genesis.py validators-active.json allocations-active.json

# Output: genesis.json
```

**What it does**:
- ✅ Creates genesis.json with all validators
- ✅ Adds token allocations
- ✅ Sets network parameters (Chain ID: 86137, Block time: 5s)
- ✅ Calculates and displays genesis hash

### Step 3: Verify Genesis

```bash
# Verify genesis file
python3 verify_genesis.py genesis.json

# Verify with expected hash
python3 verify_genesis.py genesis.json 0xf058de4562...
```

**Validation checks**:
- ✅ JSON format valid
- ✅ Chain ID = 86137
- ✅ Consensus = PoPC
- ✅ Validators ≥ 3
- ✅ All validator addresses unique
- ✅ Total supply calculated

### Step 4: Distribute Genesis

**Option A: Manual Distribution**
```bash
# Copy to validators
scp genesis.json root@VALIDATOR_IP:~/.axionax/config/
```

**Option B: Automated (if validators-active.json has IPs)**
```bash
# Launch script will distribute automatically
bash launch_genesis.sh
```

**Option C: Public Download**
```bash
# Upload to web server
scp genesis.json user@testnet.axionax.org:/var/www/html/

# Validators download
wget https://testnet.axionax.org/genesis.json -O ~/.axionax/config/genesis.json
```

### Step 5: Validators Verify Hash

All validators must verify genesis hash matches:

```bash
# On validator VPS
sha256sum ~/.axionax/config/genesis.json

# Compare with announced hash
# If hash matches, proceed to initialization
```

### Step 6: Initialize Validator Nodes

Each validator initializes their node:

```bash
# On validator VPS
axionax-core init \
  --config ~/.axionax/config/config.yaml \
  --genesis ~/.axionax/config/genesis.json

# Setup systemd service
sudo bash ~/axionax-core/scripts/setup_systemd.sh

# DO NOT start yet - wait for coordinated launch
```

### Step 7: Coordinated Launch

**Option A: Using Launch Script (Recommended)**
```bash
# On coordinator machine (with SSH access to validators)
bash launch_genesis.sh
```

**What it does**:
1. ✅ Verifies all validators have genesis.json
2. ✅ Checks genesis hash on all nodes
3. ✅ Starts coordinator node first
4. ✅ Gets bootstrap enode
5. ✅ Launches all validator nodes
6. ✅ Monitors network health

**Option B: Manual Launch**
```bash
# T-5 min: Coordinator starts first
sudo systemctl start axionax-validator

# Get enode
curl -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
  | jq -r '.result.enode'

# Share enode with validators

# T-0: All validators start simultaneously
ssh root@VALIDATOR_IP "sudo systemctl start axionax-validator"
```

---

## 📊 Monitoring Launch

### Check Block Production

```bash
# Watch blocks being produced
watch -n 1 'curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" \
  | jq -r ".result" | xargs printf "%d\n"'
```

Expected: Block number increases every 5 seconds

### Check Peer Count

```bash
# Check connected peers
curl -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  | jq -r '.result' | xargs printf "%d\n"
```

Expected: Peer count = Number of validators - 1

### Check Validator Participation

```bash
# Check which validators are producing blocks
for i in {1..20}; do
  curl -s -X POST http://127.0.0.1:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
    | jq -r '.result.miner'
  sleep 5
done
```

Expected: All validator addresses should appear

### Check Node Logs

```bash
# On any validator
journalctl -u axionax-validator -f

# Look for:
# ✅ "Imported new chain segment" (blocks syncing)
# ✅ "Consensus reached" (validators agreeing)
# ❌ "Connection refused" (peer issues)
# ❌ "Consensus failed" (network issues)
```

---

## 🎯 Success Criteria

Genesis launch is successful when:

- [x] All validators online and connected
- [x] Blocks produced consistently (5s intervals)
- [x] No chain forks detected
- [x] All validators participating in consensus
- [x] Network produces 720+ blocks in first hour
- [x] No error logs or crashes

---

## 🚨 Troubleshooting

### Genesis hash doesn't match
```bash
# Delete and re-download genesis
rm ~/.axionax/config/genesis.json
wget https://testnet.axionax.org/genesis.json -O ~/.axionax/config/genesis.json
sha256sum ~/.axionax/config/genesis.json
```

### Validator can't connect to peers
```bash
# Check firewall
sudo ufw status
sudo ufw allow 30303/tcp  # P2P port

# Try manual peer addition
curl -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"admin_addPeer","params":["BOOTSTRAP_ENODE"],"id":1}'
```

### No blocks being produced
```bash
# Check validator status
systemctl status axionax-validator

# Check logs for errors
journalctl -u axionax-validator -n 100 --no-pager

# Verify genesis time hasn't passed if configured
python3 -c "from datetime import datetime; print(datetime.fromtimestamp(GENESIS_TIMESTAMP))"
```

### Network forked
```bash
# Identify canonical chain (longest/most validators)
# Stop minority validators
ssh root@MINORITY_VALIDATOR "sudo systemctl stop axionax-validator"

# Delete blockchain data
ssh root@MINORITY_VALIDATOR "rm -rf ~/.axionax/data/blockchain"

# Reinitialize and restart
ssh root@MINORITY_VALIDATOR "axionax-core init --genesis ~/.axionax/config/genesis.json"
ssh root@MINORITY_VALIDATOR "sudo systemctl start axionax-validator"
```

---

## 📞 Support

- **Discord**: #genesis-launch channel
- **Telegram**: Validators Group (private)
- **Email**: validators@axionax.org
- **Docs**: https://docs.axionax.org/genesis-ceremony

---

## 📝 Post-Launch Tasks

After successful genesis launch:

1. **Monitor for 24 hours**
   - Watch Grafana dashboards
   - Check validator uptime
   - Verify block production

2. **Enable Public Services** (after 1 hour)
   - Start RPC nodes
   - Deploy block explorer
   - Activate faucet

3. **Public Announcement**
   - Share genesis hash
   - Publish RPC endpoints
   - Announce to community

4. **Documentation**
   - Update README with actual genesis hash
   - Document any issues encountered
   - Share lessons learned

---

## 🎉 Genesis Info (Fill after launch)

**Network**: axionax Testnet  
**Chain ID**: 86137  
**Genesis Time**: TBD  
**Genesis Hash**: TBD  
**Initial Validators**: 5  
**Total Supply**: 1,000,250,000 AXX  

**Bootstrap Node**: TBD  
**RPC Endpoint**: https://testnet-rpc.axionax.org  
**Explorer**: https://testnet-explorer.axionax.org  
**Faucet**: https://testnet-faucet.axionax.org  

---

**Good luck with your genesis launch! 🚀**
