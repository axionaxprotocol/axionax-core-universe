#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yaml"
BINARY_NAME="${BINARY_NAME:-axionaxd}"
SNAPSHOT_URL="${SNAPSHOT_URL:-}"
STATE_SYNC_RPC="${STATE_SYNC_RPC:-}"
STATE_SYNC_TRUST_HEIGHT="${STATE_SYNC_TRUST_HEIGHT:-0}"
STATE_SYNC_TRUST_HASH="${STATE_SYNC_TRUST_HASH:-}"

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

echo "Starting RPC service (if not already running)..."
docker compose -f "${COMPOSE_FILE}" up -d rpc

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

validate_container rpc

download_snapshot() {
  local url="$1"
  if [[ -z "$url" ]]; then
    echo "No snapshot URL provided; skipping snapshot download"
    return
  fi
  echo "Downloading snapshot from ${url}"
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "curl -fsSL '${url}' | lz4 -d | tar -x -C /data/axionax" || {
    echo "warning: snapshot download failed" >&2
  }
}

configure_state_sync() {
  if [[ -z "${STATE_SYNC_RPC}" || -z "${STATE_SYNC_TRUST_HASH}" || "${STATE_SYNC_TRUST_HEIGHT}" -le 0 ]]; then
    echo "State sync parameters incomplete; skipping configuration"
    return
  fi
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "${BINARY_NAME} configure set statesync.rpc_servers '${STATE_SYNC_RPC}'"
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "${BINARY_NAME} configure set statesync.trust_height ${STATE_SYNC_TRUST_HEIGHT}"
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "${BINARY_NAME} configure set statesync.trust_hash ${STATE_SYNC_TRUST_HASH}"
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "${BINARY_NAME} configure set statesync.enable true"
}

cleanup_old_state() {
  echo "Pruning any existing blockchain data"
  docker compose -f "${COMPOSE_FILE}" exec rpc bash -c "rm -rf /data/axionax/data && mkdir -p /data/axionax/data"
}

cleanup_old_state
download_snapshot "${SNAPSHOT_URL}"
configure_state_sync

echo "Restarting RPC node to apply configuration"
docker compose -f "${COMPOSE_FILE}" restart rpc

echo "RPC bootstrap complete"
