#!/usr/bin/env bash
# =============================================================================
# VDN-MiniMax-H3 Weight Download Script
# Downloads ~82GB checkpoint from Hugging Face: h3-base, stage-b-step-2000, stage-dmd-step-250
# Layout: /models/ckpts/{h3-base,stage-b-step-2000,stage-dmd-step-250}
# Skip download if checkpoints already exist (JuiceFS-friendly, no concurrent multi-replica download)
# =============================================================================
set -euo pipefail

CKPT_DIR="${CKPT_DIR:-/models/ckpts}"
HF_REPO="OpenVDN/vdn-minimax-h3"
HF_TOKEN="${HF_TOKEN:-}"
HF_ENDPOINT="${HF_ENDPOINT:-https://huggingface.co}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[DOWNLOAD]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[DOWNLOAD WARN]${NC} $*"
}

# Check if checkpoint already exists
check_checkpoint() {
    local stage=$1
    local marker_file="${CKPT_DIR}/${stage}/.download_complete"
    
    if [ -f "$marker_file" ]; then
        log_info "Checkpoint ${stage} already exists (found marker: ${marker_file}), skipping download"
        return 0
    else
        return 1
    fi
}

# Download checkpoint
download_checkpoint() {
    local stage=$1
    local marker_file="${CKPT_DIR}/${stage}/.download_complete"
    
    log_info "Downloading checkpoint: ${stage} (~82GB total, may take 10-30 minutes)"
    
    mkdir -p "${CKPT_DIR}"
    
    # Build hf download command
    local cmd="hf download ${HF_REPO} --local-dir ${CKPT_DIR}"
    
    if [ -n "$HF_TOKEN" ]; then
        cmd="$cmd --token ${HF_TOKEN}"
    fi
    
    # Execute download
    log_info "Running: $cmd"
    eval "$cmd"
    
    # Mark download complete
    touch "$marker_file"
    log_info "Download complete: ${stage}"
}

main() {
    log_info "VDN-MiniMax-H3 Weight Download"
    log_info "Repository: ${HF_REPO}"
    log_info "Target directory: ${CKPT_DIR}"
    log_info "HF Endpoint: ${HF_ENDPOINT}"
    echo ""
    
    # Check if any critical checkpoint exists
    if check_checkpoint "h3-base" && check_checkpoint "stage-dmd-step-250"; then
        log_info "All critical checkpoints exist, skipping download"
        log_info "To force re-download, remove ${CKPT_DIR}/*/.download_complete"
        exit 0
    fi
    
    # Download full repository (all checkpoints at once)
    log_info "Downloading complete VDN-H3 checkpoint (~82GB):"
    log_info "  - h3-base/             (~72GB)  MiniMax H3 transformer + VAEs"
    log_info "  - stage-b-step-2000/   (~4.3GB) VDN-H3-50-step (default LoRA)"
    log_info "  - stage-dmd-step-250/  (~5.1GB) VDN-H3-8-step (turbo LoRA, fastest)"
    echo ""
    
    mkdir -p "${CKPT_DIR}"
    
    # Build and execute hf download command
    local cmd="hf download ${HF_REPO} --local-dir ${CKPT_DIR}"
    
    if [ -n "$HF_TOKEN" ]; then
        cmd="$cmd --token ${HF_TOKEN}"
    fi
    
    log_info "Executing: $cmd"
    eval "$cmd"
    
    # Mark downloads complete
    mkdir -p "${CKPT_DIR}/h3-base" "${CKPT_DIR}/stage-b-step-2000" "${CKPT_DIR}/stage-dmd-step-250"
    touch "${CKPT_DIR}/h3-base/.download_complete"
    touch "${CKPT_DIR}/stage-b-step-2000/.download_complete"
    touch "${CKPT_DIR}/stage-dmd-step-250/.download_complete"
    
    log_info "All checkpoints downloaded successfully!"
    log_info ""
    log_info "Checkpoint layout:"
    du -sh "${CKPT_DIR}"/* 2>/dev/null || true
}

main "$@"
