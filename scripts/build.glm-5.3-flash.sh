#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="${ENGINE:-sglang}"; TAG="${TAG:-latest}"; REGISTRY="${REGISTRY:-}"; REPO="${REPO:-}"
docker build -f "${ROOT_DIR}/engines/llm/Dockerfile.${ENGINE}.glm-5.3-flash" -t "engines/llm:${ENGINE}-glm-5.3-flash-${TAG}" "${ROOT_DIR}/engines/llm"
docker build -f "${ROOT_DIR}/products/glm-5.3-flash/Dockerfile" --build-arg ENGINE="${ENGINE}" --build-arg TAG="${TAG}" --build-arg REGISTRY="${REGISTRY}" --build-arg REPO="${REPO}" -t "ai-images/glm-5.3-flash:${ENGINE}-${TAG}" "${ROOT_DIR}"
