#!/usr/bin/env bash
# vLLM engine entrypoint
set -euo pipefail

MODE="${1:-serve}"
shift || true

MODEL="${MODEL:-}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
TP_SIZE="${TENSOR_PARALLEL_SIZE:-1}"

case "${MODE}" in
  serve|api)
    if [[ -z "${MODEL}" ]]; then
      echo "ERROR: set MODEL env (HF id or local path), e.g. MODEL=meta-llama/Llama-3.1-8B-Instruct" >&2
      exit 1
    fi
    exec python -m vllm.entrypoints.openai.api_server \
      --model "${MODEL}" \
      --host "${HOST}" \
      --port "${PORT}" \
      --tensor-parallel-size "${TP_SIZE}" \
      "$@"
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  *)
    exec "${MODE}" "$@"
    ;;
esac
