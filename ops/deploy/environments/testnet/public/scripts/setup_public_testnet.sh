#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yaml"
BASE_ENV_FILE="${ROOT_DIR}/.env.example"

usage() {
  cat <<'EOF'
Usage: setup_public_testnet.sh [--role ROLE] [--dry-run]

Options:
  --role ROLE    Role to deploy (validator|rpc|bootnode|explorer|faucet|monitoring|all). Default: all
  --dry-run      Print docker compose command without executing
  -h, --help     Show this help message
EOF
}

ROLE="all"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="${2:-}"
      if [[ -z "${ROLE}" ]]; then
        echo "error: --role requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found in PATH" >&2
    exit 1
  fi
}

require_command docker
require_command sed
require_command mktemp

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "error: docker-compose.yaml not found at ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${BASE_ENV_FILE}" ]]; then
  echo "error: base env file not found at ${BASE_ENV_FILE}" >&2
  exit 1
fi

case "${ROLE}" in
  validator)
    SERVICES=(validator)
    ROLE_ENV="${ROOT_DIR}/.env.validator"
    ;;
  rpc)
    SERVICES=(rpc)
    ROLE_ENV="${ROOT_DIR}/.env.rpc"
    ;;
  bootnode)
    SERVICES=(bootnode)
    ROLE_ENV="${ROOT_DIR}/.env.bootnode"
    ;;
  explorer)
    SERVICES=(explorer postgres redis)
    ROLE_ENV="${ROOT_DIR}/.env.explorer"
    ;;
  faucet)
    SERVICES=(faucet)
    ROLE_ENV="${ROOT_DIR}/.env.faucet"
    ;;
  monitoring)
    SERVICES=(prometheus grafana node-exporter)
    ROLE_ENV="${ROOT_DIR}/.env.monitoring"
    ;;
  all)
    SERVICES=(validator rpc bootnode explorer faucet prometheus grafana node-exporter postgres redis)
    ROLE_ENV=""
    ;;
  *)
    echo "error: unknown role '${ROLE}'" >&2
    usage
    exit 1
    ;;
 esac

if [[ "${ROLE}" != "all" && ! -f "${ROLE_ENV}" ]]; then
  echo "warning: role-specific env file ${ROLE_ENV} not found; proceeding with base env only" >&2
  ROLE_ENV=""
fi

TMP_ENV="$(mktemp -t axx-public-testnet-env.XXXXXX)"
trap 'rm -f "${TMP_ENV}"' EXIT

# Merge environment files, preserving comments for clarity
grep -E '^#|^[A-Za-z0-9_]+=.*' "${BASE_ENV_FILE}" > "${TMP_ENV}"
if [[ -n "${ROLE_ENV}" ]]; then
  printf '\n' >> "${TMP_ENV}"
  grep -E '^#|^[A-Za-z0-9_]+=.*' "${ROLE_ENV}" >> "${TMP_ENV}"
fi

# Ensure data directories exist for stateful services
mkdir -p "${ROOT_DIR}/data/validator" "${ROOT_DIR}/data/rpc" "${ROOT_DIR}/data/bootnode" \
         "${ROOT_DIR}/data/faucet" "${ROOT_DIR}/data/explorer" "${ROOT_DIR}/data/postgres" \
         "${ROOT_DIR}/data/prometheus" "${ROOT_DIR}/data/grafana"

COMMAND=(docker compose --env-file "${TMP_ENV}" -f "${COMPOSE_FILE}" up -d "${SERVICES[@]}")

if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Dry run: '
  printf '%q ' "${COMMAND[@]}"
  printf '\n'
else
  echo "Starting services: ${SERVICES[*]}"
  "${COMMAND[@]}"
fi
