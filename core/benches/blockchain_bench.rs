use criterion::{black_box, criterion_group, criterion_main, Criterion};
use axionax_blockchain::{Block, Blockchain, Transaction};

fn benchmark_block_validation(c: &mut Criterion) {
    let blockchain = Blockchain::new();
    let block = Block::new(
        1,
        vec![],
        "0000000000000000000000000000000000000000000000000000000000000000".to_string(),
        1699999999,
    );

    c.bench_function("validate_block", |b| {
        b.iter(|| {
            black_box(blockchain.validate_block(&block));
        });
    });
}

fn benchmark_add_transaction(c: &mut Criterion) {
    let mut blockchain = Blockchain::new();
    let tx = Transaction {
        from: "0xaaa".to_string(),
        to: "0xbbb".to_string(),
        value: 1000,
        nonce: 0,
        gas_limit: 21000,
        gas_price: 1_000_000_000,
        data: vec![],
        signature: None,
    };

    c.bench_function("add_pending_transaction", |b| {
        b.iter(|| {
            black_box(blockchain.add_pending_transaction(tx.clone()).ok());
        });
    });
}

criterion_group!(benches, benchmark_block_validation, benchmark_add_transaction);
criterion_main!(benches);
