#!/usr/bin/env bash
# Qwen-Image-2.1 Diffusers product entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

# Load variant-specific defaults
if [ -f /etc/profile.d/variant.sh ]; then
  source /etc/profile.d/variant.sh
fi

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
MODEL_PATH="${MODEL_PATH:-/models}"
AUTO_DOWNLOAD_WEIGHTS="${AUTO_DOWNLOAD_WEIGHTS:-0}"
VARIANT="${VARIANT:-unknown}"

echo "==> Qwen-Image-2.1 Diffusers API (Variant: ${VARIANT})"
echo "    TORCH_DTYPE: ${TORCH_DTYPE:-auto}"
echo "    DEFAULT_WIDTH: ${DEFAULT_WIDTH:-1024}"
echo "    DEFAULT_HEIGHT: ${DEFAULT_HEIGHT:-1024}"
echo "    ENABLE_CPU_OFFLOAD: ${ENABLE_CPU_OFFLOAD:-0}"

if [[ "${AUTO_DOWNLOAD_WEIGHTS}" == "1" || "${AUTO_DOWNLOAD_WEIGHTS}" == "true" ]]; then
  echo "==> AUTO_DOWNLOAD_WEIGHTS=1 — fetching weights"
  /usr/local/bin/download_weights.sh
fi

case "${MODE}" in
  serve|api)
    exec /usr/local/bin/entrypoint.sh serve "$@"
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
