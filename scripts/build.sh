#!/usr/bin/env bash
# =============================================================================
# Build AI images in dependency order: bases → engines → products
# Usage:
#   ./scripts/build.sh              # Build all layers
#   ./scripts/build.sh base         # Build base images only
#   ./scripts/build.sh engine       # Build engine images only
#   ./scripts/build.sh product      # Build product images only
#   ./scripts/build.sh bases/cuda-runtime  # Build single image
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

# Determine image naming: ghcr.io/gpurun/<tier>/<name> or local <tier>/<name>
IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"
IMAGE_PREFIX="${IMAGE_PREFIX:-}"

build_image() {
  local dockerfile_dir="$1"
  local tier="$2"       # base, engine, product
  local name="$3"       # cuda-runtime, comfyui, video-minimax-h3-singularity, etc.
  local tag="$4"
  local base_image="${5:-}"  # Parent image (optional for cuda-runtime)
  local build_context="${6:-${dockerfile_dir}}"  # Build context (default: same as dockerfile_dir)

  echo ""
  echo "========================================================================"
  echo "Building ${tier}/${name}:${tag}"
  echo "========================================================================"

  local full_tag
  if [[ -n "${IMAGE_REGISTRY}" ]]; then
    full_tag="${IMAGE_REGISTRY}/${tier}/${name}:${tag}"
  else
    full_tag="${tier}/${name}:${tag}"
  fi

  local build_args=(
    --tag "${full_tag}"
    --file "${dockerfile_dir}/Dockerfile"
  )

  # Pass versions as build args
  [[ -n "${CUDA_IMAGE_TAG:-}" ]] && build_args+=(--build-arg "CUDA_IMAGE_TAG=${CUDA_IMAGE_TAG}")
  [[ -n "${PYTHON_VERSION:-}" ]] && build_args+=(--build-arg "PYTHON_VERSION=${PYTHON_VERSION}")
  [[ -n "${TORCH_VERSION:-}" ]] && build_args+=(--build-arg "TORCH_VERSION=${TORCH_VERSION}")
  [[ -n "${TORCHVISION_VERSION:-}" ]] && build_args+=(--build-arg "TORCHVISION_VERSION=${TORCHVISION_VERSION}")
  [[ -n "${TORCHAUDIO_VERSION:-}" ]] && build_args+=(--build-arg "TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION}")
  [[ -n "${TORCH_INDEX_URL:-}" ]] && build_args+=(--build-arg "TORCH_INDEX_URL=${TORCH_INDEX_URL}")
  [[ -n "${VLLM_VERSION:-}" ]] && build_args+=(--build-arg "VLLM_VERSION=${VLLM_VERSION}")
  [[ -n "${SGLANG_VERSION:-}" ]] && build_args+=(--build-arg "SGLANG_VERSION=${SGLANG_VERSION}")
  [[ -n "${COMFYUI_REF:-}" ]] && build_args+=(--build-arg "COMFYUI_REF=${COMFYUI_REF}")

  # Override base image if dependency provided
  if [[ -n "${base_image}" ]]; then
    build_args+=(--build-arg "BASE_IMAGE=${base_image}")
  fi

  build_args+=("${build_context}")

  echo "→ docker build ${build_args[*]}"
  docker build "${build_args[@]}"

  echo "✓ Built: ${full_tag}"
}

build_bases() {
  echo "==> Building base images..."
  
  # cuda-runtime has no parent (FROM nvidia/cuda directly)
  build_image \
    "bases/cuda-runtime" \
    "base" \
    "cuda-runtime" \
    "${BASE_CUDA_RUNTIME_TAG}" \
    ""

  # python-ml depends on cuda-runtime
  local cuda_runtime_image
  if [[ -n "${IMAGE_REGISTRY}" ]]; then
    cuda_runtime_image="${IMAGE_REGISTRY}/base/cuda-runtime:${BASE_CUDA_RUNTIME_TAG}"
  else
    cuda_runtime_image="base/cuda-runtime:${BASE_CUDA_RUNTIME_TAG}"
  fi

  build_image \
    "bases/python-ml" \
    "base" \
    "python-ml" \
    "${BASE_PYTHON_ML_TAG}" \
    "${cuda_runtime_image}"
}

build_engines() {
  echo "==> Building engine images..."
  
  local python_ml_image
  if [[ -n "${IMAGE_REGISTRY}" ]]; then
    python_ml_image="${IMAGE_REGISTRY}/base/python-ml:${BASE_PYTHON_ML_TAG}"
  else
    python_ml_image="base/python-ml:${BASE_PYTHON_ML_TAG}"
  fi

  # ComfyUI engine
  build_image \
    "engines/comfyui" \
    "engine" \
    "comfyui" \
    "${COMFYUI_REF}" \
    "${python_ml_image}"

  # vLLM engine
  build_image \
    "engines/llm/vllm" \
    "engine" \
    "vllm" \
    "v${VLLM_VERSION}" \
    "${python_ml_image}"

  # SGLang engine
  build_image \
    "engines/llm/sglang" \
    "engine" \
    "sglang" \
    "v${SGLANG_VERSION}" \
    "${python_ml_image}"

  # Diffusers API engine
  build_image \
    "engines/diffusers-api" \
    "engine" \
    "diffusers-api" \
    "${DIFFUSERS_API_TAG}" \
    "${python_ml_image}"
}

build_products() {
  echo "==> Building product images..."
  
  local comfyui_image
  local diffusers_api_image
  
  if [[ -n "${IMAGE_REGISTRY}" ]]; then
    comfyui_image="${IMAGE_REGISTRY}/engine/comfyui:${COMFYUI_REF}"
    diffusers_api_image="${IMAGE_REGISTRY}/engine/diffusers-api:${DIFFUSERS_API_TAG}"
  else
    comfyui_image="engine/comfyui:${COMFYUI_REF}"
    diffusers_api_image="engine/diffusers-api:${DIFFUSERS_API_TAG}"
  fi

  # video-minimax-h3-singularity product
  build_image \
    "products/video-minimax-h3-singularity" \
    "product" \
    "video-minimax-h3-singularity" \
    "${PRODUCT_VIDEO_MINIMAX_H3_SINGULARITY_TAG}" \
    "${comfyui_image}"

  # Qwen-Image-2.1 Diffusers products
  build_image \
    "products/image-qwen-image-21-diffusers-4090-24g" \
    "product" \
    "image-qwen-image-21-diffusers-4090-24g" \
    "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_4090_24G_TAG}" \
    "${diffusers_api_image}" \
    "products"

  build_image \
    "products/image-qwen-image-21-diffusers-48g" \
    "product" \
    "image-qwen-image-21-diffusers-48g" \
    "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_48G_TAG}" \
    "${diffusers_api_image}" \
    "products"

  build_image \
    "products/image-qwen-image-21-diffusers-5090" \
    "product" \
    "image-qwen-image-21-diffusers-5090" \
    "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_5090_TAG}" \
    "${diffusers_api_image}" \
    "products"

  # Qwen-Image-2.1 ComfyUI products
  build_image \
    "products/image-qwen-image-21-comfyui-4090-24g" \
    "product" \
    "image-qwen-image-21-comfyui-4090-24g" \
    "${PRODUCT_QWEN_IMAGE_21_COMFYUI_4090_24G_TAG}" \
    "${comfyui_image}" \
    "products"

  build_image \
    "products/image-qwen-image-21-comfyui-48g" \
    "product" \
    "image-qwen-image-21-comfyui-48g" \
    "${PRODUCT_QWEN_IMAGE_21_COMFYUI_48G_TAG}" \
    "${comfyui_image}" \
    "products"

  build_image \
    "products/image-qwen-image-21-comfyui-5090" \
    "product" \
    "image-qwen-image-21-comfyui-5090" \
    "${PRODUCT_QWEN_IMAGE_21_COMFYUI_5090_TAG}" \
    "${comfyui_image}" \
    "products"
}

build_single() {
  local path="$1"
  
  case "${path}" in
    bases/cuda-runtime)
      build_image "bases/cuda-runtime" "base" "cuda-runtime" "${BASE_CUDA_RUNTIME_TAG}" ""
      ;;
    bases/python-ml)
      local cuda_rt
      [[ -n "${IMAGE_REGISTRY}" ]] && cuda_rt="${IMAGE_REGISTRY}/base/cuda-runtime:${BASE_CUDA_RUNTIME_TAG}" || cuda_rt="base/cuda-runtime:${BASE_CUDA_RUNTIME_TAG}"
      build_image "bases/python-ml" "base" "python-ml" "${BASE_PYTHON_ML_TAG}" "${cuda_rt}"
      ;;
    engines/comfyui)
      local py_ml
      [[ -n "${IMAGE_REGISTRY}" ]] && py_ml="${IMAGE_REGISTRY}/base/python-ml:${BASE_PYTHON_ML_TAG}" || py_ml="base/python-ml:${BASE_PYTHON_ML_TAG}"
      build_image "engines/comfyui" "engine" "comfyui" "${COMFYUI_REF}" "${py_ml}"
      ;;
    engines/llm/vllm)
      local py_ml
      [[ -n "${IMAGE_REGISTRY}" ]] && py_ml="${IMAGE_REGISTRY}/base/python-ml:${BASE_PYTHON_ML_TAG}" || py_ml="base/python-ml:${BASE_PYTHON_ML_TAG}"
      build_image "engines/llm/vllm" "engine" "vllm" "v${VLLM_VERSION}" "${py_ml}"
      ;;
    engines/llm/sglang)
      local py_ml
      [[ -n "${IMAGE_REGISTRY}" ]] && py_ml="${IMAGE_REGISTRY}/base/python-ml:${BASE_PYTHON_ML_TAG}" || py_ml="base/python-ml:${BASE_PYTHON_ML_TAG}"
      build_image "engines/llm/sglang" "engine" "sglang" "v${SGLANG_VERSION}" "${py_ml}"
      ;;
    products/video-minimax-h3-singularity)
      local comfy
      [[ -n "${IMAGE_REGISTRY}" ]] && comfy="${IMAGE_REGISTRY}/engine/comfyui:${COMFYUI_REF}" || comfy="engine/comfyui:${COMFYUI_REF}"
      build_image "products/video-minimax-h3-singularity" "product" "video-minimax-h3-singularity" "${PRODUCT_VIDEO_MINIMAX_H3_SINGULARITY_TAG}" "${comfy}"
      ;;
    engines/diffusers-api)
      local py_ml
      [[ -n "${IMAGE_REGISTRY}" ]] && py_ml="${IMAGE_REGISTRY}/base/python-ml:${BASE_PYTHON_ML_TAG}" || py_ml="base/python-ml:${BASE_PYTHON_ML_TAG}"
      build_image "engines/diffusers-api" "engine" "diffusers-api" "${DIFFUSERS_API_TAG}" "${py_ml}"
      ;;
    products/image-qwen-image-21-diffusers-4090-24g)
      local diffusers
      [[ -n "${IMAGE_REGISTRY}" ]] && diffusers="${IMAGE_REGISTRY}/engine/diffusers-api:${DIFFUSERS_API_TAG}" || diffusers="engine/diffusers-api:${DIFFUSERS_API_TAG}"
      build_image "products/image-qwen-image-21-diffusers-4090-24g" "product" "image-qwen-image-21-diffusers-4090-24g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_4090_24G_TAG}" "${diffusers}" "products"
      ;;
    products/image-qwen-image-21-diffusers-48g)
      local diffusers
      [[ -n "${IMAGE_REGISTRY}" ]] && diffusers="${IMAGE_REGISTRY}/engine/diffusers-api:${DIFFUSERS_API_TAG}" || diffusers="engine/diffusers-api:${DIFFUSERS_API_TAG}"
      build_image "products/image-qwen-image-21-diffusers-48g" "product" "image-qwen-image-21-diffusers-48g" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_48G_TAG}" "${diffusers}" "products"
      ;;
    products/image-qwen-image-21-diffusers-5090)
      local diffusers
      [[ -n "${IMAGE_REGISTRY}" ]] && diffusers="${IMAGE_REGISTRY}/engine/diffusers-api:${DIFFUSERS_API_TAG}" || diffusers="engine/diffusers-api:${DIFFUSERS_API_TAG}"
      build_image "products/image-qwen-image-21-diffusers-5090" "product" "image-qwen-image-21-diffusers-5090" "${PRODUCT_QWEN_IMAGE_21_DIFFUSERS_5090_TAG}" "${diffusers}" "products"
      ;;
    products/image-qwen-image-21-comfyui-4090-24g)
      local comfy
      [[ -n "${IMAGE_REGISTRY}" ]] && comfy="${IMAGE_REGISTRY}/engine/comfyui:${COMFYUI_REF}" || comfy="engine/comfyui:${COMFYUI_REF}"
      build_image "products/image-qwen-image-21-comfyui-4090-24g" "product" "image-qwen-image-21-comfyui-4090-24g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_4090_24G_TAG}" "${comfy}" "products"
      ;;
    products/image-qwen-image-21-comfyui-48g)
      local comfy
      [[ -n "${IMAGE_REGISTRY}" ]] && comfy="${IMAGE_REGISTRY}/engine/comfyui:${COMFYUI_REF}" || comfy="engine/comfyui:${COMFYUI_REF}"
      build_image "products/image-qwen-image-21-comfyui-48g" "product" "image-qwen-image-21-comfyui-48g" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_48G_TAG}" "${comfy}" "products"
      ;;
    products/image-qwen-image-21-comfyui-5090)
      local comfy
      [[ -n "${IMAGE_REGISTRY}" ]] && comfy="${IMAGE_REGISTRY}/engine/comfyui:${COMFYUI_REF}" || comfy="engine/comfyui:${COMFYUI_REF}"
      build_image "products/image-qwen-image-21-comfyui-5090" "product" "image-qwen-image-21-comfyui-5090" "${PRODUCT_QWEN_IMAGE_21_COMFYUI_5090_TAG}" "${comfy}" "products"
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
    build_bases
    build_engines
    build_products
    echo ""
    echo "✓ All images built successfully!"
    ;;
  base|bases)
    build_bases
    echo "✓ Base images built!"
    ;;
  engine|engines)
    build_engines
    echo "✓ Engine images built!"
    ;;
  product|products)
    build_products
    echo "✓ Product images built!"
    ;;
  bases/*|engines/*|products/*)
    build_single "${TARGET}"
    echo "✓ Image ${TARGET} built!"
    ;;
  *)
    echo "Usage: $0 [all|base|engine|product|<path>]"
    echo ""
    echo "Examples:"
    echo "  $0                  # Build all"
    echo "  $0 base             # Build base images"
    echo "  $0 bases/cuda-runtime   # Build single base"
    echo "  $0 products/video-minimax-h3-singularity"
    exit 1
    ;;
esac
