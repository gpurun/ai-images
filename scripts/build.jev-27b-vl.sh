#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${ROOT_DIR}/versions.env" ]]; then set -a; source "${ROOT_DIR}/versions.env"; set +a; fi
ENGINE="${ENGINE:-vllm}"; TAG="${TAG:-latest}"; REGISTRY="${REGISTRY:-}"; REPO="${REPO:-}"
docker build -f "${ROOT_DIR}/engines/llm/Dockerfile.${ENGINE}.jev-27b-vl" --build-arg OLLAMA_VERSION="${OLLAMA_VERSION:-0.35.1}" -t "engines/llm:${ENGINE}-jev-27b-vl-${TAG}" "${ROOT_DIR}/engines/llm"
docker build -f "${ROOT_DIR}/products/jev-27b-vl/Dockerfile" --build-arg ENGINE="${ENGINE}" --build-arg TAG="${TAG}" --build-arg REGISTRY="${REGISTRY}" --build-arg REPO="${REPO}" -t "ai-images/jev-27b-vl:${ENGINE}-${TAG}" "${ROOT_DIR}"
