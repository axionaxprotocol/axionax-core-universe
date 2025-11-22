#!/usr/bin/env python3
"""
Genesis Verification Script
Verifies genesis.json integrity and calculates hash
"""

import json
import hashlib
import sys
from pathlib import Path

def calculate_hash(filepath: str) -> str:
    """Calculate SHA-256 hash of genesis file"""
    with open(filepath, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()

def verify_genesis(filepath: str, expected_hash: str = None):
    """Verify genesis file"""
    print("=" * 60)
    print("Genesis Verification Tool")
    print("=" * 60)
    
    # Check file exists
    if not Path(filepath).is_file():
        print(f"❌ File not found: {filepath}")
        return False
    
    # Calculate hash
    print(f"\nFile: {filepath}")
    genesis_hash = calculate_hash(filepath)
    print(f"Genesis Hash: 0x{genesis_hash}")
    
    # Verify hash if provided
    if expected_hash:
        expected = expected_hash.replace("0x", "").lower()
        if genesis_hash == expected:
            print("✅ Hash matches expected value!")
        else:
            print(f"❌ Hash mismatch!")
            print(f"   Expected: 0x{expected}")
            print(f"   Got:      0x{genesis_hash}")
            return False
    
    # Load and validate JSON
    try:
        with open(filepath, 'r') as f:
            genesis = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON: {e}")
        return False
    
    print("\n" + "=" * 60)
    print("Genesis Contents")
    print("=" * 60)
    
    # Chain config
    config = genesis.get("config", {})
    print(f"\nChain ID: {config.get('chainId', 'NOT SET')}")
    print(f"Consensus: {config.get('axionax', {}).get('consensus', 'NOT SET')}")
    print(f"Block Time: {config.get('axionax', {}).get('blockTime', 'NOT SET')}s")
    
    # Genesis time
    timestamp = genesis.get("timestamp", "0x0")
    from datetime import datetime
    try:
        ts = int(timestamp, 16)
        dt = datetime.fromtimestamp(ts)
        print(f"Genesis Time: {dt.isoformat()} UTC")
    except:
        print(f"Genesis Time: {timestamp} (raw)")
    
    # Validators
    validators = genesis.get("validators", [])
    print(f"\nValidators: {len(validators)}")
    for i, v in enumerate(validators, 1):
        print(f"  {i}. {v.get('name', 'Unnamed')} - {v.get('address', 'NO ADDRESS')}")
        print(f"     Stake: {int(v.get('stake', '0')) / 10**18:.0f} AXX")
        print(f"     Commission: {v.get('commission', 0) * 100:.1f}%")
    
    # Allocations
    alloc = genesis.get("alloc", {})
    print(f"\nAllocations: {len(alloc)} addresses")
    
    total_supply = 0
    for addr, data in alloc.items():
        balance = data.get("balance", "0")
        try:
            bal_int = int(balance, 16 if balance.startswith("0x") else 10)
            total_supply += bal_int
        except:
            pass
    
    print(f"Total Supply: {total_supply / 10**18:,.0f} AXX")
    print(f"             ({total_supply / 10**18:.2e} wei)")
    
    # Validation checks
    print("\n" + "=" * 60)
    print("Validation Checks")
    print("=" * 60)
    
    issues = []
    warnings = []
    
    # Check validators
    if len(validators) == 0:
        issues.append("No validators defined")
    elif len(validators) < 3:
        warnings.append(f"Only {len(validators)} validators (minimum 3 recommended)")
    elif len(validators) < 5:
        warnings.append(f"Only {len(validators)} validators (5+ recommended for stability)")
    
    # Check chain ID
    if config.get("chainId") != 86137:
        issues.append(f"Chain ID is {config.get('chainId')}, expected 86137")
    
    # Check consensus
    if config.get("axionax", {}).get("consensus") != "popc":
        issues.append("Consensus is not 'popc'")
    
    # Check validator addresses unique
    validator_addrs = [v.get("address") for v in validators]
    if len(validator_addrs) != len(set(validator_addrs)):
        issues.append("Duplicate validator addresses found")
    
    # Check allocations
    if len(alloc) == 0:
        warnings.append("No token allocations defined")
    
    # Print results
    if issues:
        print("\n❌ CRITICAL ISSUES:")
        for issue in issues:
            print(f"   - {issue}")
    
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"   - {warning}")
    
    if not issues and not warnings:
        print("\n✅ All checks passed!")
    
    print("\n" + "=" * 60)
    if issues:
        print("❌ VALIDATION FAILED")
        print("=" * 60)
        return False
    else:
        print("✅ GENESIS IS VALID")
        print("=" * 60)
        print(f"\nGenesis Hash: 0x{genesis_hash}")
        print("\nNext Steps:")
        print("1. Distribute genesis.json to all validators")
        print("2. Announce genesis hash publicly")
        print("3. Validators verify hash matches")
        print("4. Initialize nodes with this genesis")
        print("5. Coordinate launch time")
        return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 verify_genesis.py <genesis.json> [expected_hash]")
        print("\nExample:")
        print("  python3 verify_genesis.py genesis.json")
        print("  python3 verify_genesis.py genesis.json 0xabcd1234...")
        sys.exit(1)
    
    genesis_file = sys.argv[1]
    expected_hash = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = verify_genesis(genesis_file, expected_hash)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
