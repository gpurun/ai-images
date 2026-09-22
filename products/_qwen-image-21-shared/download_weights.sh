#!/usr/bin/env bash
# Download Qwen-Image-2.1 model weights
# Supports variants: 4090-24g (FP8/GGUF), 48g (BF16 full), 5090 (BF16)
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-Qwen/Qwen-Image-2.1}"
WEIGHTS_ROOT="${WEIGHTS_ROOT:-/models}"
VARIANT="${VARIANT:-4090-24g}"
HF_TOKEN="${HF_TOKEN:-}"

mkdir -p "${WEIGHTS_ROOT}"

echo "==> Downloading Qwen-Image-2.1 for variant: ${VARIANT}"
echo "    Model: ${MODEL_PATH}"
echo "    Target: ${WEIGHTS_ROOT}"

# Determine which files to download based on variant
case "${VARIANT}" in
  4090-24g)
    echo "==> 24GB VRAM SKU: downloading FP8 quantized model (if available) or FP16"
    # Note: As of Dec 2024, check if Qwen-Image-2.1 has official FP8/GGUF variants
    # For now, download full model and rely on runtime quantization via transformers/optimum
    # TODO: Update to specific FP8 variant when available
    REVISION="main"
    ;;
  48g)
    echo "==> 48GB VRAM SKU: downloading full BF16 model"
    REVISION="main"
    ;;
  5090)
    echo "==> RTX 5090 32GB SKU: downloading full BF16 model (same as 48g)"
    REVISION="main"
    ;;
  *)
    echo "ERROR: Unknown variant '${VARIANT}'" >&2
    exit 1
    ;;
esac

# Use huggingface-cli or hf to download
if command -v hf >/dev/null 2>&1; then
  HF_CMD="hf"
elif command -v huggingface-cli >/dev/null 2>&1; then
  HF_CMD="huggingface-cli"
else
  echo "ERROR: neither 'hf' nor 'huggingface-cli' found" >&2
  exit 1
fi

# Download full model repo
echo "==> Downloading ${MODEL_PATH} (revision: ${REVISION})"

if [ "${HF_CMD}" = "hf" ]; then
  hf download "${MODEL_PATH}" \
    --local-dir "${WEIGHTS_ROOT}" \
    --local-dir-use-symlinks False \
    ${HF_TOKEN:+--token "${HF_TOKEN}"} \
    ${REVISION:+--revision "${REVISION}"}
else
  huggingface-cli download "${MODEL_PATH}" \
    --local-dir "${WEIGHTS_ROOT}" \
    --local-dir-use-symlinks False \
    ${HF_TOKEN:+--token "${HF_TOKEN}"} \
    ${REVISION:+--revision "${REVISION}"}
fi

echo "==> Download complete: ${WEIGHTS_ROOT}"
echo ""
echo "Model: ${MODEL_PATH}"
echo "Variant: ${VARIANT}"
echo "Storage: $(du -sh "${WEIGHTS_ROOT}" 2>/dev/null | cut -f1 || echo 'N/A')"
echo ""
echo "NOTE: For 4090-24g variant, FP8 quantization may occur at runtime."
echo "      Check Qwen-Image-2.1 repo for official quantized checkpoints."
