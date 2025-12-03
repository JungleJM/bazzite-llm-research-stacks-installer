#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="bazzite-comfyui-rocm"
CONTAINER_NAME="comfyui-rocm"
HOST_COMFY_DIR="/home/j/ai/comfyui"
HOST_MODELS_DIR="/home/j/ai/models"

if ! podman image exists "${IMAGE_NAME}"; then
  ./build-container.sh
fi

podman run --rm -it \
  --name "${CONTAINER_NAME}-shell" \
  --device /dev/kfd \
  --device /dev/dri \
  --group-add keep-groups \
  -e ROC_ENABLE_PRE_VEGA=1 \
  -v "${HOST_COMFY_DIR}:/opt/comfyui:Z" \
  -v "${HOST_MODELS_DIR}:/models:Z" \
  "${IMAGE_NAME}" \
  /bin/bash
