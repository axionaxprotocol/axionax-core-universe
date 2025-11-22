#!/usr/bin/env python3
"""
Genesis Configuration Generator for axionax Testnet
Creates genesis.json with initial validators and token allocations
"""

import json
import hashlib
import secrets
from datetime import datetime, timezone
from typing import List, Dict, Any

# Testnet Configuration
CHAIN_ID = "axionax-testnet-1"
CHAIN_NAME = "axionax Public Testnet"
GENESIS_TIME = datetime.now(timezone.utc).isoformat()

# Token Economics
TOTAL_SUPPLY = 1_000_000_000  # 1 billion AXX
INITIAL_FAUCET_ALLOCATION = 10_000_000  # 10M AXX for faucet
TEAM_ALLOCATION = 100_000_000  # 100M AXX for team
VALIDATOR_REWARDS_POOL = 200_000_000  # 200M AXX for staking rewards
COMMUNITY_ALLOCATION = 690_000_000  # 690M AXX for community

# Consensus Parameters
BLOCK_TIME = 6  # seconds
MAX_VALIDATORS = 100
MIN_VALIDATOR_STAKE = 10_000  # 10K AXX minimum stake

# PoPC Parameters
CHALLENGE_INTERVAL = 100  # blocks
VERIFICATION_THRESHOLD = 0.67  # 67% verification required


def generate_validator_keypair():
    """Generate a validator keypair"""
    private_key = secrets.token_hex(32)
    # In production, derive public key from private key properly
    public_key = hashlib.sha256(private_key.encode()).hexdigest()
    address = "0x" + hashlib.sha256(public_key.encode()).hexdigest()[:40]
    
    return {
        "private_key": "0x" + private_key,
        "public_key": "0x" + public_key,
        "address": address
    }


def create_genesis_validators(count: int = 4) -> List[Dict[str, Any]]:
    """Create initial genesis validators"""
    validators = []
    
    for i in range(count):
        keypair = generate_validator_keypair()
        validator = {
            "address": keypair["address"],
            "pub_key": {
                "type": "tendermint/PubKeyEd25519",
                "value": keypair["public_key"]
            },
            "power": str(1000000),  # Initial voting power
            "name": f"Genesis Validator {i + 1}",
            "stake": str(MIN_VALIDATOR_STAKE * 10)  # 100K AXX stake
        }
        validators.append(validator)
        
        # Save validator keys (for manual distribution)
        print(f"\n{'='*60}")
        print(f"Validator {i + 1}:")
        print(f"  Address: {keypair['address']}")
        print(f"  Public Key: {keypair['public_key']}")
        print(f"  Private Key: {keypair['private_key']}")
        print(f"  ⚠️  KEEP PRIVATE KEY SECURE!")
        print(f"{'='*60}")
    
    return validators


def create_genesis_accounts() -> List[Dict[str, Any]]:
    """Create initial account allocations"""
    
    # Faucet account
    faucet_keypair = generate_validator_keypair()
    print(f"\n{'='*60}")
    print("FAUCET ACCOUNT:")
    print(f"  Address: {faucet_keypair['address']}")
    print(f"  Private Key: {faucet_keypair['private_key']}")
    print(f"  ⚠️  Add to .env as FAUCET_PRIVATE_KEY")
    print(f"{'='*60}")
    
    # Team account
    team_keypair = generate_validator_keypair()
    print(f"\n{'='*60}")
    print("TEAM ACCOUNT:")
    print(f"  Address: {team_keypair['address']}")
    print(f"  Private Key: {team_keypair['private_key']}")
    print(f"  ⚠️  KEEP TEAM PRIVATE KEY SECURE!")
    print(f"{'='*60}")
    
    accounts = [
        {
            "address": faucet_keypair["address"],
            "balance": str(INITIAL_FAUCET_ALLOCATION * 10**18),  # Convert to wei
            "type": "faucet"
        },
        {
            "address": team_keypair["address"],
            "balance": str(TEAM_ALLOCATION * 10**18),
            "type": "team"
        },
        {
            "address": "0x" + "0" * 40,  # Null address for rewards pool
            "balance": str(VALIDATOR_REWARDS_POOL * 10**18),
            "type": "rewards_pool"
        }
    ]
    
    return accounts


def create_genesis_config() -> Dict[str, Any]:
    """Create complete genesis configuration"""
    
    print("\n🚀 Generating axionax Testnet Genesis Configuration...\n")
    
    validators = create_genesis_validators(4)
    accounts = create_genesis_accounts()
    
    genesis = {
        "genesis_time": GENESIS_TIME,
        "chain_id": CHAIN_ID,
        "chain_name": CHAIN_NAME,
        
        "consensus_params": {
            "block": {
                "max_bytes": "22020096",
                "max_gas": "10000000",
                "time_iota_ms": str(BLOCK_TIME * 1000)
            },
            "evidence": {
                "max_age_num_blocks": "100000",
                "max_age_duration": "172800000000000",
                "max_bytes": "1048576"
            },
            "validator": {
                "pub_key_types": ["ed25519"]
            },
            "version": {}
        },
        
        "popc_params": {
            "challenge_interval": CHALLENGE_INTERVAL,
            "verification_threshold": str(VERIFICATION_THRESHOLD),
            "max_validators": MAX_VALIDATORS,
            "min_validator_stake": str(MIN_VALIDATOR_STAKE * 10**18)
        },
        
        "validators": validators,
        
        "app_hash": "",
        
        "app_state": {
            "accounts": accounts,
            "auth": {
                "params": {
                    "max_memo_characters": "256",
                    "tx_sig_limit": "7",
                    "tx_size_cost_per_byte": "10",
                    "sig_verify_cost_ed25519": "590",
                    "sig_verify_cost_secp256k1": "1000"
                }
            },
            "bank": {
                "params": {
                    "send_enabled": True,
                    "default_send_enabled": True
                },
                "balances": [
                    {
                        "address": acc["address"],
                        "coins": [
                            {
                                "denom": "axx",
                                "amount": acc["balance"]
                            }
                        ]
                    }
                    for acc in accounts
                ],
                "supply": [
                    {
                        "denom": "axx",
                        "amount": str(TOTAL_SUPPLY * 10**18)
                    }
                ],
                "denom_metadata": [
                    {
                        "description": "The native staking token of axionax",
                        "denom_units": [
                            {
                                "denom": "axx",
                                "exponent": 0,
                                "aliases": ["microaxx"]
                            },
                            {
                                "denom": "AXX",
                                "exponent": 18,
                                "aliases": []
                            }
                        ],
                        "base": "axx",
                        "display": "AXX",
                        "name": "axionax Token",
                        "symbol": "AXX"
                    }
                ]
            },
            "staking": {
                "params": {
                    "unbonding_time": "1814400s",  # 21 days
                    "max_validators": MAX_VALIDATORS,
                    "max_entries": 7,
                    "historical_entries": 10000,
                    "bond_denom": "axx"
                },
                "validators": [
                    {
                        "operator_address": val["address"],
                        "consensus_pubkey": val["pub_key"],
                        "jailed": False,
                        "status": 3,  # Bonded
                        "tokens": val["stake"],
                        "delegator_shares": val["stake"],
                        "description": {
                            "moniker": val["name"],
                            "identity": "",
                            "website": "",
                            "security_contact": "",
                            "details": "Genesis validator for axionax testnet"
                        },
                        "unbonding_height": "0",
                        "unbonding_time": "1970-01-01T00:00:00Z",
                        "commission": {
                            "commission_rates": {
                                "rate": "0.100000000000000000",
                                "max_rate": "0.200000000000000000",
                                "max_change_rate": "0.010000000000000000"
                            },
                            "update_time": GENESIS_TIME
                        },
                        "min_self_delegation": "1"
                    }
                    for val in validators
                ]
            },
            "distribution": {
                "params": {
                    "community_tax": "0.020000000000000000",
                    "base_proposer_reward": "0.010000000000000000",
                    "bonus_proposer_reward": "0.040000000000000000",
                    "withdraw_addr_enabled": True
                },
                "fee_pool": {
                    "community_pool": []
                }
            },
            "gov": {
                "starting_proposal_id": "1",
                "deposits": [],
                "votes": [],
                "proposals": [],
                "deposit_params": {
                    "min_deposit": [
                        {
                            "denom": "axx",
                            "amount": "10000000000000000000000"  # 10K AXX
                        }
                    ],
                    "max_deposit_period": "172800s"  # 2 days
                },
                "voting_params": {
                    "voting_period": "172800s"  # 2 days
                },
                "tally_params": {
                    "quorum": "0.334000000000000000",
                    "threshold": "0.500000000000000000",
                    "veto_threshold": "0.334000000000000000"
                }
            }
        }
    }
    
    return genesis


def save_genesis(genesis: Dict[str, Any], filename: str = "genesis.json"):
    """Save genesis configuration to file"""
    with open(filename, 'w') as f:
        json.dump(genesis, f, indent=2)
    print(f"\n✅ Genesis configuration saved to: {filename}")


def generate_validator_instructions(validators: List[Dict[str, Any]]):
    """Generate instructions for validator setup"""
    
    instructions = """
# Validator Setup Instructions

## Prerequisites
- Ubuntu 20.04+ VPS
- 4GB RAM, 2 CPU cores
- 100GB SSD
- Static IP address

## Setup Steps

1. Clone and build axionax node:
```bash
git clone https://github.com/axionaxprotocol/axionax-core.git
cd axionax-core
cargo build --release
```

2. Initialize node:
```bash
./target/release/axionax-node init --chain-id axionax-testnet-1
```

3. Copy genesis.json:
```bash
wget https://raw.githubusercontent.com/axionaxprotocol/axionax-deploy/main/genesis.json
cp genesis.json ~/.axionax/config/genesis.json
```

4. Configure validator key:
```bash
# Use the private key provided to you
echo "YOUR_PRIVATE_KEY" > ~/.axionax/config/priv_validator_key.json
```

5. Configure persistent peers:
```bash
# Add to ~/.axionax/config/config.toml
persistent_peers = "validator1@ip1:26656,validator2@ip2:26656,..."
```

6. Start validator:
```bash
./target/release/axionax-node start
```

7. Create validator transaction:
```bash
./target/release/axionax-node tx staking create-validator \\
  --amount=10000000000000000000000axx \\
  --pubkey=$(./target/release/axionax-node tendermint show-validator) \\
  --moniker="Your Validator Name" \\
  --chain-id=axionax-testnet-1 \\
  --commission-rate="0.10" \\
  --commission-max-rate="0.20" \\
  --commission-max-change-rate="0.01" \\
  --min-self-delegation="1" \\
  --from=validator
```

## Monitoring
- Check node status: `curl http://localhost:26657/status`
- View logs: `journalctl -u axionax-node -f`
- Check sync status: Check `catching_up` in status response

## Security
- ✅ Keep private keys secure and backed up
- ✅ Use firewall (only allow 26656, 26657, 22)
- ✅ Enable DDoS protection
- ✅ Use monitoring tools (Prometheus/Grafana)
- ✅ Regular backups of validator key

## Support
- Discord: https://discord.gg/axionax
- Docs: https://docs.axionax.org
- Issues: https://github.com/axionaxprotocol/axionax-core/issues
"""
    
    with open("VALIDATOR_SETUP.md", 'w') as f:
        f.write(instructions)
    
    print(f"\n✅ Validator setup instructions saved to: VALIDATOR_SETUP.md")


if __name__ == "__main__":
    # Generate genesis configuration
    genesis = create_genesis_config()
    
    # Save to file
    save_genesis(genesis)
    
    # Generate validator instructions
    generate_validator_instructions(genesis["validators"])
    
    print("\n" + "="*60)
    print("🎉 GENESIS CONFIGURATION COMPLETE!")
    print("="*60)
    print(f"\nChain ID: {CHAIN_ID}")
    print(f"Total Supply: {TOTAL_SUPPLY:,} AXX")
    print(f"Genesis Validators: {len(genesis['validators'])}")
    print(f"Initial Accounts: {len(genesis['app_state']['accounts'])}")
    print(f"\n⚠️  IMPORTANT: Securely store all private keys!")
    print(f"⚠️  Distribute validator keys to respective operators")
    print(f"⚠️  Keep faucet private key in .env file")
    print("\n" + "="*60 + "\n")
