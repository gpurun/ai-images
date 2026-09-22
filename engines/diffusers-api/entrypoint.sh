#!/usr/bin/env bash
# Diffusers API engine entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
MODEL_PATH="${MODEL_PATH:-Qwen/Qwen-Image-2.1}"
WORKERS="${WORKERS:-1}"

case "${MODE}" in
  serve|api)
    cd /opt/diffusers-api
    exec uvicorn server:app \
      --host "${HOST}" \
      --port "${PORT}" \
      --workers "${WORKERS}" \
      --log-level info \
      "$@"
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
