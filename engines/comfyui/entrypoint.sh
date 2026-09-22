#!/usr/bin/env bash
# ComfyUI engine entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

HOST="${HOST:-0.0.0.0}"
PORT="${COMFYUI_PORT:-${PORT:-8188}}"
COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"

case "${MODE}" in
  serve|ui)
    cd "${COMFY_DIR}"
    exec python main.py \
      --listen "${HOST}" \
      --port "${PORT}" \
      "$@"
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
