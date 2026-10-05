#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Load version pins (OLLAMA_VERSION, VLLM/SGLANG pins, ...)
if [[ -f "${ROOT_DIR}/versions.env" ]]; then set -a; source "${ROOT_DIR}/versions.env"; set +a; fi
ENGINE="${ENGINE:-sglang}"
TAG="${TAG:-latest}"
REGISTRY="${REGISTRY:-}"
REPO="${REPO:-}"

echo "Building DeepSeek-V4.1-Flash with engine=${ENGINE}, tag=${TAG}"

docker build \
  -f "${ROOT_DIR}/engines/llm/Dockerfile.${ENGINE}.deepseek-v4.1-flash" \
  --build-arg OLLAMA_VERSION="${OLLAMA_VERSION:-0.35.1}" \
  -t "engines/llm:${ENGINE}-deepseek-v4.1-flash-${TAG}" \
  "${ROOT_DIR}/engines/llm"

docker build \
  -f "${ROOT_DIR}/products/deepseek-v4.1-flash/Dockerfile" \
  --build-arg ENGINE="${ENGINE}" \
  --build-arg TAG="${TAG}" \
  --build-arg REGISTRY="${REGISTRY}" \
  --build-arg REPO="${REPO}" \
  -t "ai-images/deepseek-v4.1-flash:${ENGINE}-${TAG}" \
  "${ROOT_DIR}"

echo "Build completed: ai-images/deepseek-v4.1-flash:${ENGINE}-${TAG}"
