#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yaml"
BINARY_NAME="${BINARY_NAME:-axionaxd}"
GENESIS_FILE="${GENESIS_FILE:-${ROOT_DIR}/pkg/genesis/public/genesis.json}"
INVENTORY_FILE="${INVENTORY_FILE:-${ROOT_DIR}/inventory.yaml}"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found" >&2
    exit 1
  fi
}

require_command docker

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "error: docker-compose.yaml not found at ${COMPOSE_FILE}" >&2
  exit 1
fi

echo "Starting validator service (if not already running)..."
docker compose -f "${COMPOSE_FILE}" up -d validator

validate_container() {
  local name="$1"
  local retries=20
  local delay=3
  for ((i=1; i<=retries; i++)); do
    if docker compose -f "${COMPOSE_FILE}" exec "$name" true >/dev/null 2>&1; then
      return 0
    fi
    sleep "$delay"
  done
  echo "error: container '$name' is not responding after $((retries*delay)) seconds" >&2
  exit 1
}

validate_container validator

echo "Initialising validator home directory (safe to re-run)"
docker compose -f "${COMPOSE_FILE}" exec validator ${BINARY_NAME} init validator-01 --chain-id axionax-testnet-1 >/dev/null 2>&1 || true

if [[ -f "${GENESIS_FILE}" ]]; then
  echo "Copying genesis file into validator container"
  docker cp "${GENESIS_FILE}" "$(docker compose -f "${COMPOSE_FILE}" ps -q validator)":/data/axionax/config/genesis.json
else
  echo "warning: genesis file not found at ${GENESIS_FILE}; skipped" >&2
fi

SEEDS=""
if [[ -f "${INVENTORY_FILE}" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    SEEDS=$(INVENTORY_FILE="${INVENTORY_FILE}" python3 <<'PY'
import yaml, os
path = os.environ['INVENTORY_FILE']
with open(path, 'r', encoding='utf-8') as fh:
    data = yaml.safe_load(fh)
seeds = []
for item in data.get('seed_nodes', []):
    host = item.get('host')
    port = item.get('p2p_port', 26656)
    node_id = item.get('node_id')
    if host and node_id:
        seeds.append(f"{node_id}@{host}:{port}")
print(','.join(seeds), end='')
PY
)
  else
    echo "warning: python3 not available, cannot parse inventory for seeds" >&2
  fi
else
  echo "warning: inventory file not found at ${INVENTORY_FILE}; skipped" >&2
fi

if [[ -n "${SEEDS}" ]]; then
  echo "Configuring persistent seeds: ${SEEDS}"
  docker compose -f "${COMPOSE_FILE}" exec validator bash -c "${BINARY_NAME} configure set p2p.persistent_peers '${SEEDS}'"
fi

echo "Validator bootstrap complete"
