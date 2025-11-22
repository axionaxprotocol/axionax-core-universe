use criterion::{black_box, criterion_group, criterion_main, Criterion};
use axionax_crypto::{generate_keypair, sign_message, verify_signature};

fn benchmark_keygen(c: &mut Criterion) {
    c.bench_function("generate_keypair", |b| {
        b.iter(|| {
            black_box(generate_keypair());
        });
    });
}

fn benchmark_sign(c: &mut Criterion) {
    let (private_key, _) = generate_keypair();
    let message = b"Hello, AxionAx!";

    c.bench_function("sign_message", |b| {
        b.iter(|| {
            black_box(sign_message(&private_key, message).unwrap());
        });
    });
}

fn benchmark_verify(c: &mut Criterion) {
    let (private_key, public_key) = generate_keypair();
    let message = b"Hello, AxionAx!";
    let signature = sign_message(&private_key, message).unwrap();

    c.bench_function("verify_signature", |b| {
        b.iter(|| {
            black_box(verify_signature(&public_key, message, &signature).unwrap());
        });
    });
}

criterion_group!(benches, benchmark_keygen, benchmark_sign, benchmark_verify);
criterion_main!(benches);
