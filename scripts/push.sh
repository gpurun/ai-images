#!/usr/bin/env bash
# =============================================================================
# Push AI images to container registry (GHCR / Docker Hub / etc.)
# Pre-requisite: Images must be built first (./scripts/build.sh)
# Usage:
#   export IMAGE_REGISTRY=ghcr.io/gpurun
#   ./scripts/push.sh                # Push all images
#   ./scripts/push.sh base           # Push base images only
#   ./scripts/push.sh products/video-minimax-h3-singularity
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# Load version pins
# Save IMAGE_REGISTRY from environment before sourcing versions.env
_SAVED_IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"

if [[ -f versions.env ]]; then
  set -a
  source versions.env
  set +a
fi

# Restore IMAGE_REGISTRY from environment if it was set
if [[ -n "${_SAVED_IMAGE_REGISTRY}" ]]; then
  IMAGE_REGISTRY="${_SAVED_IMAGE_REGISTRY}"
fi

IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"

if [[ -z "${IMAGE_REGISTRY}" ]]; then
  echo "ERROR: IMAGE_REGISTRY not set. Cannot push local-only tags." >&2
  echo "       Set IMAGE_REGISTRY=ghcr.io/gpurun (or your registry) and rebuild." >&2
  exit 1
fi

push_image() {
  local tier="$1"  # base, engine, product
  local name="$2"
  local tag="$3"

  local full_tag="${IMAGE_REGISTRY}/${tier}/${name}:${tag}"

  echo ""
  echo "========================================================================"
  echo "Pushing ${tier}/${name}:${tag}"
  echo "========================================================================"
  echo "→ docker push ${full_tag}"
  
  docker push "${full_tag}"
  
  echo "✓ Pushed: ${full_tag}"
}

push_bases() {
  echo "==> Pushing base images..."
  push_image "base" "cuda-runtime" "${BASE_CUDA_RUNTIME_TAG}"
  push_image "base" "python-ml" "${BASE_PYTHON_ML_TAG}"
}

push_engines() {
  echo "==> Pushing engine images..."
  push_image "engine" "comfyui" "${COMFYUI_REF}"
  push_image "engine" "vllm" "v${VLLM_VERSION}"
  push_image "engine" "sglang" "v${SGLANG_VERSION}"
  push_image "engine" "diffusers-api" "${DIFFUSERS_API_TAG}"
}

push_products() {
  echo "==> Pushing product images..."
  push_image "product" "video-minimax-h3-singularity" "${PRODUCT_VIDEO_MINIMAX_H3_SINGULARITY_TAG}"
  
  # Qwen-Image-2.1 products
  push_image "product" "image-qwen-image-21-diffusers-4090-24g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_4090_24G_TAG}"
  push_image "product" "image-qwen-image-21-diffusers-48g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_48G_TAG}"
  push_image "product" "image-qwen-image-21-diffusers-5090" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_5090_TAG}"
  push_image "product" "image-qwen-image-21-comfyui-4090-24g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_4090_24G_TAG}"
  push_image "product" "image-qwen-image-21-comfyui-48g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_48G_TAG}"
  push_image "product" "image-qwen-image-21-comfyui-5090" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_5090_TAG}"
}

push_single() {
  local path="$1"
  
  case "${path}" in
    bases/cuda-runtime)
      push_image "base" "cuda-runtime" "${BASE_CUDA_RUNTIME_TAG}"
      ;;
    bases/python-ml)
      push_image "base" "python-ml" "${BASE_PYTHON_ML_TAG}"
      ;;
    engines/comfyui)
      push_image "engine" "comfyui" "${COMFYUI_REF}"
      ;;
    engines/diffusers-api)
      push_image "engine" "diffusers-api" "${DIFFUSERS_API_TAG}"
      ;;
    engines/llm/vllm)
      push_image "engine" "vllm" "v${VLLM_VERSION}"
      ;;
    engines/llm/sglang)
      push_image "engine" "sglang" "v${SGLANG_VERSION}"
      ;;
    products/video-minimax-h3-singularity)
      push_image "product" "video-minimax-h3-singularity" "${PRODUCT_VIDEO_MINIMAX_H3_SINGULARITY_TAG}"
      ;;
    products/image-qwen-image-21-diffusers-4090-24g)
      push_image "product" "image-qwen-image-21-diffusers-4090-24g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_4090_24G_TAG}"
      ;;
    products/image-qwen-image-21-diffusers-48g)
      push_image "product" "image-qwen-image-21-diffusers-48g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_48G_TAG}"
      ;;
    products/image-qwen-image-21-diffusers-5090)
      push_image "product" "image-qwen-image-21-diffusers-5090" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_5090_TAG}"
      ;;
    products/image-qwen-image-21-comfyui-4090-24g)
      push_image "product" "image-qwen-image-21-comfyui-4090-24g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_4090_24G_TAG}"
      ;;
    products/image-qwen-image-21-comfyui-48g)
      push_image "product" "image-qwen-image-21-comfyui-48g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_48G_TAG}"
      ;;
    products/image-qwen-image-21-comfyui-5090)
      push_image "product" "image-qwen-image-21-comfyui-5090" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_5090_TAG}"
      ;;
    *)
      echo "ERROR: Unknown path '${path}'" >&2
      exit 1
      ;;
  esac
}

# Main logic
TARGET="${1:-all}"

case "${TARGET}" in
  all)
    push_bases
    push_engines
    push_products
    echo ""
    echo "✓ All images pushed successfully to ${IMAGE_REGISTRY}!"
    ;;
  base|bases)
    push_bases
    echo "✓ Base images pushed!"
    ;;
  engine|engines)
    push_engines
    echo "✓ Engine images pushed!"
    ;;
  product|products)
    push_products
    echo "✓ Product images pushed!"
    ;;
  bases/*|engines/*|products/*)
    push_single "${TARGET}"
    echo "✓ Image ${TARGET} pushed!"
    ;;
  *)
    echo "Usage: $0 [all|base|engine|product|<path>]"
    echo ""
    echo "Pre-requisite: export IMAGE_REGISTRY=ghcr.io/gpurun"
    echo ""
    echo "Examples:"
    echo "  $0                  # Push all"
    echo "  $0 base             # Push base images"
    echo "  $0 products/video-minimax-h3-singularity"
    exit 1
    ;;
esac
