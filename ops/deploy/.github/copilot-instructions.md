# Axionax Deploy - Copilot Instructions
# Target Model: Claude 4.5 Sonnet

**Context:** Docker, Kubernetes, Terraform, Ansible.

## 🔒 DEVOPS STANDARDS
1.  **Idempotency:**
    - Scripts must be re-runnable without side effects.
    - Example: Check if a docker network exists before creating it.

2.  **Security Hardening:**
    - **NO SECRETS:** Use `${ENV_VAR}` for everything.
    - Set read-only filesystems for containers where possible.
    - Use specific tags (e.g., `postgres:16-alpine`), NEVER `latest`.

3.  **Observability:**
    - Ensure all services expose metrics on `:9090/metrics` (Prometheus).
    - Configure JSON logging for production services.

4.  **Shell Scripting:**
    - Always start with `#!/bin/bash`.
    - Use `set -euo pipefail` for strict error handling.
