#!/usr/bin/env bash
# SGLang engine entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

MODEL="${MODEL:-}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-30000}"
TP_SIZE="${TENSOR_PARALLEL_SIZE:-1}"

case "${MODE}" in
  serve|api)
    if [[ -z "${MODEL}" ]]; then
      echo "ERROR: set MODEL env (HF id or local path)" >&2
      exit 1
    fi
    exec python -m sglang.launch_server \
      --model-path "${MODEL}" \
      --host "${HOST}" \
      --port "${PORT}" \
      --tp "${TP_SIZE}" \
      "$@"
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
