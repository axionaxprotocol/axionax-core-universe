"""
Example: Worker selection using Auto Selection Router
"""

from deai.asr import AutoSelectionRouter, Worker

def main():
    print("AxionAx ASR Worker Selection Example\n")
    
    # Initialize ASR
    asr = AutoSelectionRouter(
        top_k=64,
        max_quota=0.125,
        exploration_rate=0.05,
        newcomer_boost=0.1
    )
    print("✓ ASR initialized")
    
    # Create sample workers
    workers = [
        Worker(
            id=f"worker_{i}",
            cpu_cores=8,
            memory_gb=16,
            gpu_count=1,
            popc_pass_rate=0.95 + (i * 0.01),
            da_reliability=0.98,
            uptime=0.99,
            quota_used=0.05
        )
        for i in range(100)
    ]
    print(f"✓ Created {len(workers)} sample workers")
    
    # Define task requirements
    requirements = {
        'cpu': 4,
        'memory': 8192,  # MB
        'gpu': 1
    }
    print(f"✓ Task requirements: {requirements}")
    
    # Select workers
    selected = asr.select_workers(
        workers=workers,
        task_requirements=requirements,
        num_workers=10
    )
    
    print(f"\n✓ Selected {len(selected)} workers:")
    for i, worker in enumerate(selected, 1):
        print(f"  {i}. {worker.id}")
        print(f"     PoPC Pass Rate: {worker.popc_pass_rate:.2%}")
        print(f"     Reliability: {worker.da_reliability:.2%}")
        print(f"     Score: {worker.final_score:.4f}")
        print()

if __name__ == "__main__":
    main()
