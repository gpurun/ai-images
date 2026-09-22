#!/usr/bin/env bash
# Product entrypoint: optional weight download, then start ComfyUI
set -euo pipefail

MODE="${1:-serve}"
shift || true

HOST="${HOST:-0.0.0.0}"
PORT="${COMFYUI_PORT:-${PORT:-8188}}"
COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
WEIGHTS_ROOT="${WEIGHTS_ROOT:-/models}"
AUTO_DOWNLOAD_WEIGHTS="${AUTO_DOWNLOAD_WEIGHTS:-0}"

link_models() {
  # Map WEIGHTS_ROOT subdirs into ComfyUI models tree (mount-friendly).
  mkdir -p "${WEIGHTS_ROOT}"
  local sub
  for sub in diffusion_models text_encoders vae checkpoints clip clip_vision \
             loras controlnet embeddings upscale_models; do
    mkdir -p "${WEIGHTS_ROOT}/${sub}"
    local target="${COMFY_DIR}/models/${sub}"
    if [[ -L "${target}" ]]; then
      ln -sfn "${WEIGHTS_ROOT}/${sub}" "${target}"
    elif [[ -d "${target}" ]]; then
      # Preserve any baked empty dirs by replacing with symlink
      rm -rf "${target}"
      ln -sfn "${WEIGHTS_ROOT}/${sub}" "${target}"
    else
      ln -sfn "${WEIGHTS_ROOT}/${sub}" "${target}"
    fi
  done

  # IO mounts
  mkdir -p /output /input
  if [[ -d /output ]]; then
    rm -rf "${COMFY_DIR}/output" 2>/dev/null || true
    ln -sfn /output "${COMFY_DIR}/output"
  fi
  if [[ -d /input ]]; then
    rm -rf "${COMFY_DIR}/input" 2>/dev/null || true
    ln -sfn /input "${COMFY_DIR}/input"
  fi
}

link_models

if [[ "${AUTO_DOWNLOAD_WEIGHTS}" == "1" || "${AUTO_DOWNLOAD_WEIGHTS}" == "true" ]]; then
  echo "==> AUTO_DOWNLOAD_WEIGHTS=1 — fetching weights into ${WEIGHTS_ROOT}"
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
