#!/usr/bin/env bash
# Qwen-Image-2.1 ComfyUI product entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

# Load variant-specific defaults
if [ -f /etc/profile.d/variant.sh ]; then
  source /etc/profile.d/variant.sh
fi

HOST="${HOST:-0.0.0.0}"
PORT="${COMFYUI_PORT:-${PORT:-8188}}"
COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
WEIGHTS_ROOT="${WEIGHTS_ROOT:-/models}"
AUTO_DOWNLOAD_WEIGHTS="${AUTO_DOWNLOAD_WEIGHTS:-0}"
VARIANT="${VARIANT:-unknown}"

echo "==> Qwen-Image-2.1 ComfyUI (Variant: ${VARIANT})"
echo "    QUANT_MODE: ${QUANT_MODE:-bf16}"
echo "    DEFAULT_WIDTH: ${DEFAULT_WIDTH:-1024}"
echo "    DEFAULT_HEIGHT: ${DEFAULT_HEIGHT:-1024}"

# Link models directory
link_models() {
  mkdir -p "${WEIGHTS_ROOT}"
  for sub in checkpoints diffusion_models vae loras controlnet embeddings; do
    mkdir -p "${WEIGHTS_ROOT}/${sub}"
    local target="${COMFY_DIR}/models/${sub}"
    if [[ ! -L "${target}" ]]; then
      rm -rf "${target}" 2>/dev/null || true
      ln -sfn "${WEIGHTS_ROOT}/${sub}" "${target}"
    fi
  done
  
  # IO mounts
  mkdir -p /output /input
  rm -rf "${COMFY_DIR}/output" "${COMFY_DIR}/input" 2>/dev/null || true
  ln -sfn /output "${COMFY_DIR}/output"
  ln -sfn /input "${COMFY_DIR}/input"
}

link_models

if [[ "${AUTO_DOWNLOAD_WEIGHTS}" == "1" || "${AUTO_DOWNLOAD_WEIGHTS}" == "true" ]]; then
  echo "==> AUTO_DOWNLOAD_WEIGHTS=1 — fetching weights"
  /usr/local/bin/download_weights.sh
fi

case "${MODE}" in
  serve|ui)
    cd "${COMFY_DIR}"
    exec python main.py \
      --listen "${HOST}" \
      --port "${PORT}" \
      "$@"
    ;;
  download)
    exec /usr/local/bin/download_weights.sh "$@"
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
