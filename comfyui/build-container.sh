#!/usr/bin/env bash
set -euo pipefail
podman build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t bazzite-comfyui-rocm \
  -f Containerfile .
