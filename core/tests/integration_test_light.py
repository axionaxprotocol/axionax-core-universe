"""
Light Integration tests for Rust-Python bridge (No ML dependencies)
"""

import sys
import os
import time

# Ensure we can find the module
# (Assuming the caller sets PYTHONPATH or we are in the right dir)

import pytest
try:
    import axionax_python as axx
except ImportError:
    print("Error: Could not import axionax_python. Make sure the shared library is in PYTHONPATH and named correctly.")
    sys.exit(1)

class TestRustPythonBridge:
    """Test PyO3 bindings work correctly"""
    
    def test_crypto_hashing(self):
        """Test hash functions exposed from Rust"""
        data = b"Hello axionax"
        
        # Test SHA3-256
        hash1 = axx.PyCrypto.sha3_256(list(data))
        assert len(hash1) == 32
        
        # Test Keccak256
        hash2 = axx.PyCrypto.keccak256(list(data))
        assert len(hash2) == 32
        
        # Same input should give same output
        hash1_again = axx.PyCrypto.sha3_256(list(data))
        assert hash1 == hash1_again
    
    def test_vrf_operations(self):
        """Test VRF prove and verify"""
        seed = [1, 2, 3, 4] * 8  # 32 bytes
        vrf = axx.PyVRF(seed)
        
        input_data = b"test_input"
        proof, hash_output = vrf.prove(list(input_data))
        
        # Proof and hash should be generated
        assert len(proof) > 0
        assert len(hash_output) > 0
        
        # Verification should succeed
        is_valid = vrf.verify(list(input_data), proof, hash_output)
        assert is_valid
        
        # Wrong input should fail
        is_invalid = vrf.verify(list(b"wrong_input"), proof, hash_output)
        assert not is_invalid
    
    def test_validator_operations(self):
        """Test validator management"""
        validator = axx.PyValidator(
            address="0x1234567890123456789012345678901234567890",
            stake=1000000,
            reputation=0.95
        )
        
        assert validator.address == "0x1234567890123456789012345678901234567890"
        assert validator.stake == 1000000
        assert validator.reputation == 0.95
        assert validator.fraud_count == 0
        assert validator.total_checks == 0
    
    def test_consensus_engine(self):
        """Test consensus engine operations"""
        engine = axx.PyConsensusEngine()
        
        # Register validators
        v1 = axx.PyValidator("validator1", 500000, 0.9)
        v2 = axx.PyValidator("validator2", 1000000, 0.95)
        
        engine.register_validator(v1)
        engine.register_validator(v2)
        
        # Check validators registered
        validators = engine.get_validators()
        assert len(validators) == 2
        
        # Calculate fraud probability
        prob = engine.fraud_probability("validator1")
        assert 0.0 <= prob <= 1.0
        
        # Generate challenge
        block_hash = [0] * 32
        challenge = engine.generate_challenge(block_hash, "validator1")
        assert len(challenge) > 0
    
    def test_blockchain_operations(self):
        """Test blockchain operations"""
        blockchain = axx.PyBlockchain()
        
        # Should have genesis block
        assert blockchain.height() == 1
        
        genesis = blockchain.get_latest_block()
        assert genesis is not None
        assert genesis.number == 0
        
        # Add a block with transactions
        tx1 = axx.PyTransaction(
            from_addr="0xabc",
            to="0xdef",
            amount=100,
            data=[]
        )
        tx2 = axx.PyTransaction(
            from_addr="0xdef",
            to="0x123",
            amount=50,
            data=[]
        )
        
        blockchain.add_block([tx1, tx2])
        
        # Check chain grew
        assert blockchain.height() == 2
        
        latest = blockchain.get_latest_block()
        assert latest.number == 1
        assert latest.transactions_count == 2
        
        # Get block by number
        block_1 = blockchain.get_block(1)
        assert block_1 is not None
        assert block_1.number == 1

class TestPerformance:
    """Performance benchmarks for integration"""
    
    def test_hash_performance(self):
        """Benchmark hashing speed"""
        data = list(b"x" * 1024)  # 1KB
        iterations = 1000
        
        start = time.time()
        for _ in range(iterations):
            axx.PyCrypto.sha3_256(data)
        duration = time.time() - start
        
        ops_per_sec = iterations / duration
        print(f"\nSHA3-256: {ops_per_sec:.0f} ops/sec")
        
        # Should be reasonably fast
        assert ops_per_sec > 500
    
    def test_blockchain_performance(self):
        """Benchmark block addition speed"""
        blockchain = axx.PyBlockchain()
        
        # Create 100 transactions
        transactions = [
            axx.PyTransaction(f"0x{i}", f"0x{i+1}", i, [])
            for i in range(100)
        ]
        
        start = time.time()
        blockchain.add_block(transactions)
        duration = time.time() - start
        
        print(f"\nBlock with 100 txs: {duration*1000:.2f}ms")
        
        # Should complete in reasonable time
        assert duration < 1.0  # Less than 1 second

if __name__ == "__main__":
    # If pytest is installed, use it. Otherwise run manually (basic)
    try:
        sys.exit(pytest.main([__file__, "-v", "-s"]))
    except ImportError:
        print("pytest not found, running manually")
        t = TestRustPythonBridge()
        t.test_crypto_hashing()
        t.test_vrf_operations()
        t.test_validator_operations()
        t.test_consensus_engine()
        t.test_blockchain_operations()
        
        p = TestPerformance()
        p.test_hash_performance()
        p.test_blockchain_performance()
        print("All tests passed!")
