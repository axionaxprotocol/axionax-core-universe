# Axionax Core - Copilot Instructions
# Project: Axionax L1 Blockchain (Multi-Language Architecture)

## 🤖 MODEL SELECTION STRATEGY
- **For Rust (`.rs`):** SWITCH TO **Claude 4.5 Sonnet**. It understands ownership/borrowing better.
- **For Python (`.py`):** SWITCH TO **GPT-5.1 (Thinking Mode)**. It solves probability math accurately.

---

## 🦀 RUST INSTRUCTIONS (Target: Claude 4.5)
**Context:** PoPC Consensus, Tokio Async, Libp2p, RocksDB.

1.  **Safety & Performance:**
    - Prioritize Safe Rust. Use `// SAFETY:` comments for any `unsafe` blocks.
    - Avoid `.clone()` on hot paths; use `Arc<T>` or references `&T`.
    - **Zero Hallucinations:** Use ONLY crates defined in `Cargo.toml`.

2.  **Error Handling:**
    - Strict `anyhow::Result` for apps, `thiserror` for libs.
    - **BANNED:** `.unwrap()`, `.expect()`. Use `match` or `?`.

3.  **Async Patterns:**
    - Ensure types are `Send + Sync` for Tokio runtime.
    - Use `tokio::select!` for managing concurrent tasks.

---

## 🐍 PYTHON / DEAI INSTRUCTIONS (Target: GPT-5.1 Thinking)
**Context:** ASR Router, Fraud Detection, Probabilistic Math.

1.  **Mathematical Precision:**
    - Implement PoPC formula exactly: `P_detect = 1 - (1 - f)^s`.
    - **Reasoning Check:** If logic involves probabilities, output a "Thinking Plan" comment before the code.

2.  **Performance:**
    - Use `numpy` vectorization. Avoid native Python loops for data processing.
    - Strict Type Hinting: `def func(x: float) -> List[int]:`.

3.  **Bridge:**
    - Use `PyO3` conventions when interfacing with Rust.
