#!/usr/bin/env python3
"""
Load Testing Suite for AxionAx RPC Endpoints
Tests throughput, latency, and reliability under various load conditions
"""

import asyncio
import aiohttp
import time
import statistics
from typing import List, Dict, Any
from dataclasses import dataclass
from datetime import datetime
import json

@dataclass
class LoadTestResult:
    """Results from a load test run"""
    test_name: str
    total_requests: int
    successful: int
    failed: int
    duration: float
    requests_per_second: float
    avg_latency: float
    p50_latency: float
    p95_latency: float
    p99_latency: float
    min_latency: float
    max_latency: float
    error_rate: float

class RPCLoadTester:
    """Load tester for JSON-RPC endpoints"""
    
    def __init__(self, url: str = "http://localhost:8545"):
        self.url = url
        self.results: List[LoadTestResult] = []
    
    async def make_request(self, session: aiohttp.ClientSession, method: str, params: List = None, request_id: int = 1) -> tuple:
        """Make a single RPC request and measure latency"""
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": request_id
        }
        
        start = time.time()
        try:
            async with session.post(self.url, json=payload, timeout=aiohttp.ClientTimeout(total=30)) as resp:
                result = await resp.json()
                latency = time.time() - start
                success = 'result' in result
                return (success, latency, result)
        except Exception as e:
            latency = time.time() - start
            return (False, latency, str(e))
    
    async def run_load_test(self, test_name: str, method: str, params: List = None, num_requests: int = 1000, concurrency: int = 10) -> LoadTestResult:
        """Run a load test with specified parameters"""
        print(f"\n{'='*70}")
        print(f"Running: {test_name}")
        print(f"  Method: {method}")
        print(f"  Requests: {num_requests}")
        print(f"  Concurrency: {concurrency}")
        print(f"{'='*70}")
        
        connector = aiohttp.TCPConnector(limit=concurrency)
        async with aiohttp.ClientSession(connector=connector) as session:
            # Warmup
            print("Warming up...")
            for _ in range(10):
                await self.make_request(session, method, params, 0)
            
            # Actual test
            print(f"Executing {num_requests} requests...")
            start_time = time.time()
            
            tasks = []
            for i in range(num_requests):
                task = self.make_request(session, method, params, i+1)
                tasks.append(task)
            
            results = await asyncio.gather(*tasks)
            
            end_time = time.time()
            duration = end_time - start_time
        
        # Analyze results
        successful = sum(1 for success, _, _ in results if success)
        failed = num_requests - successful
        latencies = [latency for _, latency, _ in results]
        
        # Calculate statistics
        avg_latency = statistics.mean(latencies)
        sorted_latencies = sorted(latencies)
        p50_latency = sorted_latencies[int(len(sorted_latencies) * 0.50)]
        p95_latency = sorted_latencies[int(len(sorted_latencies) * 0.95)]
        p99_latency = sorted_latencies[int(len(sorted_latencies) * 0.99)]
        min_latency = min(latencies)
        max_latency = max(latencies)
        
        rps = num_requests / duration
        error_rate = (failed / num_requests) * 100
        
        result = LoadTestResult(
            test_name=test_name,
            total_requests=num_requests,
            successful=successful,
            failed=failed,
            duration=duration,
            requests_per_second=rps,
            avg_latency=avg_latency,
            p50_latency=p50_latency,
            p95_latency=p95_latency,
            p99_latency=p99_latency,
            min_latency=min_latency,
            max_latency=max_latency,
            error_rate=error_rate
        )
        
        self.results.append(result)
        self.print_result(result)
        
        return result
    
    def print_result(self, result: LoadTestResult):
        """Print test result in a formatted way"""
        print(f"\n{'-'*70}")
        print(f"Results for: {result.test_name}")
        print(f"{'-'*70}")
        print(f"  Total Requests:     {result.total_requests:,}")
        print(f"  Successful:         {result.successful:,} ({(result.successful/result.total_requests)*100:.1f}%)")
        print(f"  Failed:             {result.failed:,} ({result.error_rate:.1f}%)")
        print(f"  Duration:           {result.duration:.2f}s")
        print(f"  Throughput:         {result.requests_per_second:.2f} req/s")
        print(f"\n  Latency Statistics:")
        print(f"    Average:          {result.avg_latency*1000:.2f}ms")
        print(f"    P50 (median):     {result.p50_latency*1000:.2f}ms")
        print(f"    P95:              {result.p95_latency*1000:.2f}ms")
        print(f"    P99:              {result.p99_latency*1000:.2f}ms")
        print(f"    Min:              {result.min_latency*1000:.2f}ms")
        print(f"    Max:              {result.max_latency*1000:.2f}ms")
        
        # Performance rating
        if result.error_rate < 1 and result.avg_latency < 0.1:
            rating = "✅ EXCELLENT"
        elif result.error_rate < 5 and result.avg_latency < 0.5:
            rating = "✅ GOOD"
        elif result.error_rate < 10:
            rating = "⚠️  ACCEPTABLE"
        else:
            rating = "❌ POOR"
        
        print(f"\n  Rating: {rating}")
        print(f"{'-'*70}")
    
    def print_summary(self):
        """Print summary of all tests"""
        print(f"\n{'='*70}")
        print(f"LOAD TEST SUMMARY")
        print(f"{'='*70}\n")
        
        print(f"{'Test Name':<40} {'RPS':>10} {'Avg Lat':>10} {'Error %':>10}")
        print(f"{'-'*70}")
        
        for result in self.results:
            print(f"{result.test_name:<40} {result.requests_per_second:>10.2f} {result.avg_latency*1000:>9.2f}ms {result.error_rate:>9.2f}%")
        
        print(f"\n{'='*70}\n")
        
        # Overall stats
        total_requests = sum(r.total_requests for r in self.results)
        total_successful = sum(r.successful for r in self.results)
        total_failed = sum(r.failed for r in self.results)
        avg_rps = statistics.mean(r.requests_per_second for r in self.results)
        avg_latency = statistics.mean(r.avg_latency for r in self.results)
        overall_error_rate = (total_failed / total_requests) * 100 if total_requests > 0 else 0
        
        print(f"Overall Statistics:")
        print(f"  Total Requests:     {total_requests:,}")
        print(f"  Successful:         {total_successful:,}")
        print(f"  Failed:             {total_failed:,}")
        print(f"  Average RPS:        {avg_rps:.2f}")
        print(f"  Average Latency:    {avg_latency*1000:.2f}ms")
        print(f"  Error Rate:         {overall_error_rate:.2f}%")
        
        # Pass/Fail
        if overall_error_rate < 1 and avg_latency < 0.1:
            verdict = "✅ PASSED - System ready for testnet"
        elif overall_error_rate < 5 and avg_latency < 0.5:
            verdict = "✅ PASSED - System acceptable for testnet"
        else:
            verdict = "⚠️  REVIEW NEEDED - Performance may need optimization"
        
        print(f"\n  Verdict: {verdict}\n")
        print(f"{'='*70}\n")
    
    def save_results(self, filename: str = "load_test_results.json"):
        """Save results to JSON file"""
        data = {
            "timestamp": datetime.now().isoformat(),
            "endpoint": self.url,
            "tests": [
                {
                    "name": r.test_name,
                    "total_requests": r.total_requests,
                    "successful": r.successful,
                    "failed": r.failed,
                    "duration": r.duration,
                    "rps": r.requests_per_second,
                    "latency": {
                        "avg": r.avg_latency,
                        "p50": r.p50_latency,
                        "p95": r.p95_latency,
                        "p99": r.p99_latency,
                        "min": r.min_latency,
                        "max": r.max_latency
                    },
                    "error_rate": r.error_rate
                }
                for r in self.results
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"Results saved to: {filename}")

async def main():
    """Run comprehensive load tests"""
    import sys
    
    # Get RPC URL from command line or use default
    rpc_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8545"
    
    print(f"""
╔════════════════════════════════════════════════════════════════════╗
║              AXIONAX RPC LOAD TESTING SUITE                        ║
╚════════════════════════════════════════════════════════════════════╝

Target: {rpc_url}
Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
""")
    
    tester = RPCLoadTester(rpc_url)
    
    # Test Suite
    try:
        # Test 1: Basic connectivity (light load)
        await tester.run_load_test(
            test_name="Basic Connectivity",
            method="eth_blockNumber",
            num_requests=100,
            concurrency=10
        )
        
        # Test 2: Moderate load
        await tester.run_load_test(
            test_name="Moderate Load - Block Number",
            method="eth_blockNumber",
            num_requests=1000,
            concurrency=50
        )
        
        # Test 3: High concurrency
        await tester.run_load_test(
            test_name="High Concurrency - Block Number",
            method="eth_blockNumber",
            num_requests=5000,
            concurrency=100
        )
        
        # Test 4: Chain ID (should be cached)
        await tester.run_load_test(
            test_name="Cached Response - Chain ID",
            method="eth_chainId",
            num_requests=1000,
            concurrency=50
        )
        
        # Test 5: Gas price
        await tester.run_load_test(
            test_name="Gas Price Query",
            method="eth_gasPrice",
            num_requests=500,
            concurrency=25
        )
        
        # Test 6: Account balance (heavier query)
        await tester.run_load_test(
            test_name="Balance Query",
            method="eth_getBalance",
            params=["0x0000000000000000000000000000000000000000", "latest"],
            num_requests=500,
            concurrency=25
        )
        
        # Test 7: Network version
        await tester.run_load_test(
            test_name="Network Version",
            method="net_version",
            num_requests=1000,
            concurrency=50
        )
        
        # Test 8: Sustained load (stress test)
        await tester.run_load_test(
            test_name="Sustained Load - 10K Requests",
            method="eth_blockNumber",
            num_requests=10000,
            concurrency=100
        )
        
        # Print summary
        tester.print_summary()
        
        # Save results
        tester.save_results()
        
        print("✅ Load testing complete!\n")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        tester.print_summary()
        tester.save_results()
    except Exception as e:
        print(f"\n\n❌ Error during testing: {e}")
        if tester.results:
            tester.print_summary()
            tester.save_results()

if __name__ == "__main__":
    asyncio.run(main())
