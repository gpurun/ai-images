#!/usr/bin/env bash
# =============================================================================
# VDN-MiniMax-H3 Dual-Mode Entrypoint
# Modes:
#   SERVE_MODE=sglang    -> SGLang Diffusion HTTP serve (default, fastest)
#   SERVE_MODE=diffusers -> Diffusers HTTP API (24GB-friendly fallback)
# =============================================================================
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[VDN-H3]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[VDN-H3 WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[VDN-H3 ERROR]${NC} $*" >&2
}

# Auto-download weights if requested
if [ "${AUTO_DOWNLOAD_WEIGHTS:-0}" = "1" ]; then
    log_info "AUTO_DOWNLOAD_WEIGHTS=1, downloading weights..."
    /usr/local/bin/download_weights.sh
fi

# Verify checkpoint directory exists
if [ ! -d "${CKPT_DIR}" ] || [ -z "$(ls -A "${CKPT_DIR}" 2>/dev/null || true)" ]; then
    log_warn "Checkpoint directory ${CKPT_DIR} is empty or missing."
    log_warn "Set AUTO_DOWNLOAD_WEIGHTS=1 or mount pre-downloaded weights to /models/ckpts"
    log_warn "Expected layout: ${CKPT_DIR}/h3-base/, ${CKPT_DIR}/stage-dmd-step-250/, etc."
fi

CMD=${1:-serve}
SERVE_MODE=${SERVE_MODE:-sglang}

# Determine model path: prefer local mounted/downloaded weights over HF hub
MODEL_PATH_ARG="OpenVDN/vdn-minimax-h3"  # Default to HF hub
if [ -d "${CKPT_DIR}/h3-base" ] && [ -d "${CKPT_DIR}/stage-dmd-step-250" ]; then
    # Local layout detected (JuiceFS mount or downloaded weights)
    MODEL_PATH_ARG="${CKPT_DIR}"
    log_info "Using local checkpoint directory: ${CKPT_DIR}"
else
    log_warn "Local checkpoints not found, will use Hugging Face hub: ${MODEL_PATH_ARG}"
    log_warn "For offline/JuiceFS usage, mount weights to ${CKPT_DIR} or set AUTO_DOWNLOAD_WEIGHTS=1"
fi

case "$CMD" in
    serve)
        case "$SERVE_MODE" in
            sglang)
                log_info "Starting SGLang Diffusion server (optimal multi-GPU mode)"
                log_info "Model path: ${MODEL_PATH_ARG}"
                log_info "GPUs: ${NUM_GPUS}, Quantization: ${QUANTIZATION}, Attention: ${ATTENTION_BACKEND}"
                log_info "Port: ${SGLANG_PORT}"
                log_info ""
                
                exec sglang serve \
                    --model-path "${MODEL_PATH_ARG}" \
                    --num-gpus "${NUM_GPUS}" \
                    --quantization "${QUANTIZATION}" \
                    --attention-backend "${ATTENTION_BACKEND}" \
                    --performance-mode "${PERFORMANCE_MODE}" \
                    --warmup-num-frames "${WARMUP_FRAMES}" \
                    --warmup-resolutions "${WARMUP_RESOLUTION}" \
                    --port "${SGLANG_PORT}" \
                    --host 0.0.0.0
                ;;
            
            diffusers)
                log_info "Starting Diffusers HTTP API server (24GB-friendly mode)"
                log_info "Model path: ${MODEL_PATH_ARG}"
                log_info "Port: ${DIFFUSERS_PORT}"
                log_info ""
                
                exec python /opt/vdn/serve_diffusers.py \
                    --model-path "${MODEL_PATH_ARG}" \
                    --port "${DIFFUSERS_PORT}" \
                    --host 0.0.0.0
                ;;
            
            *)
                log_error "Unknown SERVE_MODE: ${SERVE_MODE}"
                log_error "Valid modes: sglang, diffusers"
                exit 1
                ;;
        esac
        ;;
    
    download)
        log_info "Manual weight download triggered"
        exec /usr/local/bin/download_weights.sh
        ;;
    
    bash|sh|/bin/bash|/bin/sh)
        log_info "Entering shell"
        exec /bin/bash
        ;;
    
    *)
        log_info "Executing: $*"
        exec "$@"
        ;;
esac
