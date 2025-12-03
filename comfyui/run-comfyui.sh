#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="bazzite-comfyui-rocm"
CONTAINER_NAME="comfyui-rocm"
HOST_COMFY_DIR="/home/j/ai/comfyui"
HOST_MODELS_DIR="/home/j/ai/models"
HOST_PORT="8188"
CONTAINER_PORT="8188"

mkdir -p "${HOST_COMFY_DIR}" "${HOST_MODELS_DIR}"

# Optional: clone ComfyUI into HOST_COMFY_DIR if not already present
if [ ! -d "${HOST_COMFY_DIR}/.git" ] && [ ! -f "${HOST_COMFY_DIR}/main.py" ]; then
  echo "ComfyUI not found in ${HOST_COMFY_DIR}, cloning..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "${HOST_COMFY_DIR}"
fi

# Common ROCm env vars for RDNA3 (7800XT may need override)
# Uncomment and tune if needed:
# export HSA_OVERRIDE_GFX_VERSION=11.0.0

# Ensure container exists/build image
if ! podman image exists "${IMAGE_NAME}"; then
  ./build-container.sh
fi

# Run container, mapping AMD GPU and dirs
podman run --rm -it \
  --name "${CONTAINER_NAME}" \
  --device /dev/kfd \
  --device /dev/dri \
  --group-add keep-groups \
  -e ROC_ENABLE_PRE_VEGA=1 \
  -v "${HOST_COMFY_DIR}:/opt/comfyui:Z" \
  -v "${HOST_MODELS_DIR}:/models:Z" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  "${IMAGE_NAME}"
