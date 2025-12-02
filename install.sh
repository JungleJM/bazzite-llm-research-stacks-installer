#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AI_STACK_DIR="${REPO_ROOT}/ai-stack"
RESEARCH_STACK_DIR="${REPO_ROOT}/research-stack"
COMFY_DIR="${REPO_ROOT}/comfyui"

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
RSTUDIOPASSWORD=${RSTUDIOPASSWORD}
JUPYTERTOKEN=${JUPYTERTOKEN}
PGADMINEMAIL=${PGADMINEMAIL}
PGADMINPASSWORD=${PGADMINPASSWORD}
LITELLMMASTERKEY=${LITELLMMASTERKEY}
EOF_ENV

  echo "[*] Created ${ENV_FILE}"
else
  echo "[*] Using existing ${ENV_FILE}"
fi

echo "[*] Installing ComfyUI setup script..."
sudo install -Dm755 "${COMFY_DIR}/setup-comfyui.sh" /usr/local/sbin/setup-comfyui.sh

echo "[*] Rendering comfyui.service for current user (${CURRENT_USER})..."
TMP_SERVICE="/tmp/comfyui.service.$$"
sed "s/YOUR_BAZZITE_USER/${CURRENT_USER}/" "${COMFY_DIR}/comfyui.service" > "${TMP_SERVICE}"

echo "[*] Installing comfyui.service..."
sudo install -Dm644 "${TMP_SERVICE}" /etc/systemd/system/comfyui.service
rm -f "${TMP_SERVICE}"

echo "[*] Running ComfyUI setup script (may take a while on first run)..."
sudo /usr/local/sbin/setup-comfyui.sh

echo "[*] Enabling ComfyUI service..."
sudo systemctl daemon-reload
sudo systemctl enable --now comfyui.service

echo "[*] Ensuring Podman network 'ai_net' exists..."
if ! podman network inspect ai_net >/dev/null 2>&1; then
  podman network create ai_net
fi

echo "[*] Bringing up AI stack via podman compose..."
cd "${AI_STACK_DIR}"
podman compose -f podman-compose.ai.yml up -d

echo "[*] Bringing up research stack via podman compose..."
cd "${RESEARCH_STACK_DIR}"
podman compose -f podman-compose.research.yml --env-file .env up -d

echo
echo "[*] Installation complete."
echo "    - ComfyUI: http://den-baz:8188"
echo "    - Open WebUI: http://den-baz:3000"
echo "    - LiteLLM proxy: http://den-baz:4000"
echo "    - PaperQA2: http://den-baz:4100 (placeholder)"
echo "    - RStudio: http://den-baz:8787"
echo "    - JupyterLab: http://den-baz:8888"
echo "    - pgAdmin: http://den-baz:5050"
