#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${ROOT_DIR}/versions.env" ]]; then set -a; source "${ROOT_DIR}/versions.env"; set +a; fi
ENGINE="${ENGINE:-sglang}"; TAG="${TAG:-latest}"; REGISTRY="${REGISTRY:-}"; REPO="${REPO:-}"
docker build -f "${ROOT_DIR}/engines/llm/Dockerfile.${ENGINE}.qwen3-8-27b" --build-arg OLLAMA_VERSION="${OLLAMA_VERSION:-0.35.1}" -t "engines/llm:${ENGINE}-qwen3-8-27b-${TAG}" "${ROOT_DIR}/engines/llm"
docker build -f "${ROOT_DIR}/products/qwen3-8-27b/Dockerfile" --build-arg ENGINE="${ENGINE}" --build-arg TAG="${TAG}" --build-arg REGISTRY="${REGISTRY}" --build-arg REPO="${REPO}" -t "ai-images/qwen3-8-27b:${ENGINE}-${TAG}" "${ROOT_DIR}"
