# axionax Public Testnet Environment

This directory contains infrastructure definitions for the axionax public testnet rollout.

## Components

- `inventory.yaml`  host definitions mapped to testnet roles
- `docker-compose.yaml`  container stack for validator, rpc, bootnode, explorer, faucet, monitoring
- `monitoring/`  Prometheus and Grafana configuration
- `bootstrap/`  Genesis files, chain specs, and secrets (ignored by git)

## Usage

1. Update `inventory.yaml` with real hostnames/IPs.
2. Copy secrets into `bootstrap/` (see `bootstrap/README.md`).
3. Run `../../scripts/setup_public_testnet.sh` to provision services over SSH.
4. Use `docker-compose --env-file .env up -d` on each role host as needed.

## Environments

- **staging**: Mirrors production with fewer validators for rehearsal.
- **public-testnet**: Official public testnet open to community.

See `../../README.md` for the high-level deployment checklist.
