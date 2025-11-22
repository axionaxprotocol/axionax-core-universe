# Changelog

All notable changes to AxionAx Core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - 2025-11-15

### Added
- Cross-platform installation scripts (Linux, macOS, Windows)
- Comprehensive API documentation (`docs/API_REFERENCE.md`)
- Example files for transactions, node operation, and ASR
- Performance benchmarks using Criterion
- Build optimization profiles for Release builds
- Clippy configuration for enhanced code quality
- EditorConfig for consistent coding style
- Unified configuration module (`core/config`)
- Protocol configuration with YAML import/export
- Support for testnet (86137) and mainnet (86150) configurations

### Changed
- Updated consensus parameters to ARCHITECTURE v1.5 compliance
  - `sample_size`: 1000 (recommended 600-1500)
  - `min_confidence`: 0.99 (99%+ required)
  - `fraud_window_blocks`: 720 (~3600s)
  - `false_pass_penalty_bps`: 500 (5%)
- ASR parameters updated
  - `top_k`: 64
  - `max_quota`: 0.125 (12.5%)
  - `exploration_rate`: 0.05 (5%)
- Optimized release builds with LTO and single codegen unit
- Protocol version upgraded from 0.1.0 to 1.8.0

### Fixed
- Parameter alignment with ARCHITECTURE specification
- Version consistency across all package manifests

## [1.7.0] - 2025-11-10

### Added
- Initial PoPC consensus implementation
- Auto Selection Router (ASR) for worker assignment
- Predictive Pricing Controller (PPC)
- Data Availability (DA) layer
- VRF-based validator selection

### Changed
- Improved network stability
- Enhanced RPC performance

## [1.0.0] - 2025-10-01

### Added
- Initial release of AxionAx Core
- Basic blockchain functionality
- Transaction processing
- P2P networking with libp2p
- JSON-RPC server
- Crypto primitives (Ed25519, SHA3, Blake2)
- Python-Rust bridge for DeAI components

[1.8.0]: https://github.com/axionaxprotocol/axionax-core/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/axionaxprotocol/axionax-core/compare/v1.0.0...v1.7.0
[1.0.0]: https://github.com/axionaxprotocol/axionax-core/releases/tag/v1.0.0
