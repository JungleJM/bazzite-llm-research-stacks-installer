#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="bazzite-comfyui-rocm"
CONTAINER_NAME="comfyui-rocm"
HOST_PORT="8188"
CONTAINER_PORT="8188"

# Host locations
HOST_COMFY_DIR="${HOME}/ai/comfyui"
THINKTANK="${HOME}/thinktank"

CHECKPOINTS_DIR="${THINKTANK}/comfyui/checkpoints"
LORAS_DIR="${THINKTANK}/comfyui/loras"
VAE_DIR="${THINKTANK}/comfyui/vae"

mkdir -p "${HOST_COMFY_DIR}" \
         "${CHECKPOINTS_DIR}" \
         "${LORAS_DIR}" \
         "${VAE_DIR}"

# Clone ComfyUI repo into HOST_COMFY_DIR if not present
if [ ! -d "${HOST_COMFY_DIR}/.git" ] && [ ! -f "${HOST_COMFY_DIR}/main.py" ]; then
  echo "ComfyUI not found in ${HOST_COMFY_DIR}, cloning..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "${HOST_COMFY_DIR}"
fi

# Build image if missing
if ! podman image exists "${IMAGE_NAME}"; then
  "$(dirname "$0")/build-container.sh"
fi

# Optional ROCm tweak for RDNA3 (uncomment and tune if needed)
# export HSA_OVERRIDE_GFX_VERSION=11.0.0

podman run --rm -it \
  --name "${CONTAINER_NAME}" \
  --device /dev/kfd \
  --device /dev/dri \
  --group-add keep-groups \
  -e ROC_ENABLE_PRE_VEGA=1 \
  -v "${HOST_COMFY_DIR}:/opt/comfyui:Z" \
  -v "${CHECKPOINTS_DIR}:/opt/comfyui/models/checkpoints:Z" \
  -v "${LORAS_DIR}:/opt/comfyui/models/loras:Z" \
  -v "${VAE_DIR}:/opt/comfyui/models/vae:Z" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  "${IMAGE_NAME}"
