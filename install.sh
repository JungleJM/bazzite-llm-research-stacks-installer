#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AI_STACK_DIR="${REPO_ROOT}/ai-stack"
RESEARCH_STACK_DIR="${REPO_ROOT}/research-stack"
COMFY_DIR="${REPO_ROOT}/comfyui"

# NOTE: This project uses /mnt/thinktank as the shared storage root
THINKTANK="/mnt/thinktank"
CURRENT_USER="${SUDO_USER:-$USER}"

echo "[*] Ensuring base directories exist on ${THINKTANK}..."
sudo mkdir -p \
  "${THINKTANK}/models" \
  "${THINKTANK}/openwebui-data" \
  "${THINKTANK}/research-stack/litellm-config" \
  "${THINKTANK}/research-stack/zotero-pdfs" \
  "${THINKTANK}/research-stack/vector-store" \
  "${THINKTANK}/research-stack/db-postgres-r" \
  "${THINKTANK}/research-stack/db-postgres-py" \
  "${THINKTANK}/research-stack/pgadmin" \
  "${THINKTANK}/research-stack/notebooks" \
  "${THINKTANK}/research-stack/shared" \
  "${THINKTANK}/research-stack/research-files" \
  "${THINKTANK}/research-stack/rstudio-home" \
  "${THINKTANK}/research-stack/jupyter-home" \
  "${THINKTANK}/comfyui/checkpoints" \
  "${THINKTANK}/comfyui/loras" \
  "${THINKTANK}/comfyui/vae"

if [ -d "${RESEARCH_STACK_DIR}/litellm-config" ]; then
  echo "[*] Syncing LiteLLM config to thinktank..."
  sudo cp -n "${RESEARCH_STACK_DIR}/litellm-config/"* \
    "${THINKTANK}/research-stack/litellm-config/" || true
fi

# Generate .env for research stack if missing
ENV_FILE="${RESEARCH_STACK_DIR}/.env"
if [ ! -f "${ENV_FILE}" ]; then
  echo "[*] Generating research-stack/.env with random secrets..."
  POSTGRESPASSWORD=$(openssl rand -base64 32)
  PYTHONPOSTGRESPASSWORD=$(openssl rand -base64 32)
  RSTUDIOPASSWORD=$(openssl rand -base64 32)
  JUPYTERTOKEN=$(openssl rand -base64 24)
  PGADMINEMAIL="admin@example.com"
  PGADMINPASSWORD=$(openssl rand -base64 32)
  LITELLMMASTERKEY=$(openssl rand -base64 48)

  cat > "${ENV_FILE}" <<EOF_ENV
POSTGRESPASSWORD=${POSTGRESPASSWORD}
PYTHONPOSTGRESPASSWORD=${PYTHONPOSTGRESPASSWORD}
RSTUDIOPASSWORD
