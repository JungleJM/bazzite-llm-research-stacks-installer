#!/usr/bin/env bash
set -euo pipefail

COMFY_USER="${SUDO_USER:-$USER}"
COMFY_ROOT="/home/${COMFY_USER}/opt/comfyui"
COMFY_VENV="${COMFY_ROOT}/venv"

CHECKPOINT_DIR="/mnt/thinktank/comfyui/checkpoints"
LORA_DIR="/mnt/thinktank/comfyui/loras"
VAE_DIR="/mnt/thinktank/comfyui/vae"

echo "[*] Installing base dependencies (Fedora/Bazzite)..."
if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y git python3 python3-venv python3-pip \
      mesa-vulkan-drivers vulkan-tools \
      rocm-smi rocminfo
fi

echo "[*] Creating model directories on /mnt/thinktank..."
sudo -u "$COMFY_USER" mkdir -p "$CHECKPOINT_DIR" "$LORA_DIR" "$VAE_DIR"

echo "[*] Cloning or updating ComfyUI in ${COMFY_ROOT}..."
if [ ! -d "$COMFY_ROOT" ]; then
  sudo -u "$COMFY_USER" mkdir -p "$(dirname "$COMFY_ROOT")"
  sudo -u "$COMFY_USER" git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_ROOT"
else
  sudo -u "$COMFY_USER" git -C "$COMFY_ROOT" pull --ff-only
fi

echo "[*] Creating Python venv (if needed)..."
if [ ! -d "$COMFY_VENV" ]; then
  sudo -u "$COMFY_USER" python3 -m venv "$COMFY_VENV"
fi

echo "[*] Installing PyTorch ROCm wheels + ComfyUI requirements..."
sudo -u "$COMFY_USER" bash -lc "
  source \"$COMFY_VENV/bin/activate\"
  pip install --upgrade pip
  pip install --index-url https://download.pytorch.org/whl/rocm6.1 \
      torch torchvision
  pip install -r \"$COMFY_ROOT/requirements.txt\"
"

echo "[*] Linking model directories into ComfyUI tree..."
sudo -u "$COMFY_USER" mkdir -p \
  \"$COMFY_ROOT/models/checkpoints\" \
  \"$COMFY_ROOT/models/loras\" \
  \"$COMFY_ROOT/models/vae\"

for d in checkpoints loras vae; do
  TARGET=\"$COMFY_ROOT/models/$d\"
  SRC=\"/mnt/thinktank/comfyui/$d\"
  if [ -d \"\$TARGET\" ] && [ ! -L \"\$TARGET\" ]; then
    sudo -u \"$COMFY_USER\" rm -rf \"\$TARGET\"
  fi
  if [ ! -L \"\$TARGET\" ]; then
    sudo -u \"$COMFY_USER\" ln -s \"\$SRC\" \"\$TARGET\"
  fi
done

echo
echo "[*] Done. ComfyUI is at $COMFY_ROOT, venv at $COMFY_VENV."
