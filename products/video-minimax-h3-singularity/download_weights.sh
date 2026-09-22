#!/usr/bin/env bash
# Download MiniMax-H3 Singularity diffusion + Comfy-Org companion weights.
# Does NOT bake weights into the image — call at runtime or with AUTO_DOWNLOAD_WEIGHTS=1.
set -euo pipefail

WEIGHTS_ROOT="${WEIGHTS_ROOT:-/models}"
HF_REPO="${HF_REPO:-WarmBloodAban/Minimax-h3_Singularity}"
DIFFUSION_FILE="${DIFFUSION_FILE:-Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors}"
COMPANION_REPO="${COMPANION_REPO:-Comfy-Org/MiniMax-H3}"
TEXT_ENCODER_FILE="${TEXT_ENCODER_FILE:-qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors}"
VIDEO_VAE_FILE="${VIDEO_VAE_FILE:-minimax_h3_video_vae_fp16.safetensors}"
AUDIO_VAE_FILE="${AUDIO_VAE_FILE:-minimax_h3_audio_vae_fp32.safetensors}"

DIFF_DIR="${WEIGHTS_ROOT}/diffusion_models"
TE_DIR="${WEIGHTS_ROOT}/text_encoders"
VAE_DIR="${WEIGHTS_ROOT}/vae"

mkdir -p "${DIFF_DIR}" "${TE_DIR}" "${VAE_DIR}"

hf_download() {
  local repo="$1"
  local remote_path="$2"
  local dest_dir="$3"
  local dest_name="$4"

  local dest="${dest_dir}/${dest_name}"
  if [[ -f "${dest}" ]]; then
    echo "==> skip (exists): ${dest}"
    return 0
  fi

  echo "==> downloading ${repo}:${remote_path} -> ${dest}"
  if command -v hf >/dev/null 2>&1; then
    hf download "${repo}" "${remote_path}" \
      --local-dir "${dest_dir}" \
      ${HF_TOKEN:+--token "${HF_TOKEN}"}
    # hf may place file with nested path; normalize to dest_name in dest_dir
    if [[ -f "${dest_dir}/${remote_path}" && "${remote_path}" != "${dest_name}" ]]; then
      mv -f "${dest_dir}/${remote_path}" "${dest}"
      # clean empty parent dirs left by nested remote_path
      rmdir -p "$(dirname "${dest_dir}/${remote_path}")" 2>/dev/null || true
    elif [[ -f "${dest_dir}/$(basename "${remote_path}")" && "$(basename "${remote_path}")" != "${dest_name}" ]]; then
      mv -f "${dest_dir}/$(basename "${remote_path}")" "${dest}"
    fi
  elif command -v huggingface-cli >/dev/null 2>&1; then
    huggingface-cli download "${repo}" "${remote_path}" \
      --local-dir "${dest_dir}" \
      --local-dir-use-symlinks False \
      ${HF_TOKEN:+--token "${HF_TOKEN}"}
    if [[ -f "${dest_dir}/${remote_path}" && "${remote_path}" != "${dest_name}" ]]; then
      mv -f "${dest_dir}/${remote_path}" "${dest}"
      rmdir -p "$(dirname "${dest_dir}/${remote_path}")" 2>/dev/null || true
    elif [[ -f "${dest_dir}/$(basename "${remote_path}")" && "$(basename "${remote_path}")" != "${dest_name}" ]]; then
      mv -f "${dest_dir}/$(basename "${remote_path}")" "${dest}"
    fi
  else
    echo "ERROR: neither 'hf' nor 'huggingface-cli' found" >&2
    exit 1
  fi
}

# Diffusion (Singularity fine-tune) — flat file at repo root
hf_download "${HF_REPO}" "${DIFFUSION_FILE}" "${DIFF_DIR}" "${DIFFUSION_FILE}"

# Companions from Comfy-Org/MiniMax-H3 (required for any H3 workflow)
hf_download "${COMPANION_REPO}" "text_encoders/${TEXT_ENCODER_FILE}" "${TE_DIR}" "${TEXT_ENCODER_FILE}"
hf_download "${COMPANION_REPO}" "vae/${VIDEO_VAE_FILE}" "${VAE_DIR}" "${VIDEO_VAE_FILE}"
hf_download "${COMPANION_REPO}" "vae/${AUDIO_VAE_FILE}" "${VAE_DIR}" "${AUDIO_VAE_FILE}"

echo "==> weights ready under ${WEIGHTS_ROOT}"
echo "    diffusion: ${DIFF_DIR}/${DIFFUSION_FILE}"
echo "    text_enc:  ${TE_DIR}/${TEXT_ENCODER_FILE}"
echo "    video_vae: ${VAE_DIR}/${VIDEO_VAE_FILE}"
echo "    audio_vae: ${VAE_DIR}/${AUDIO_VAE_FILE}"
echo
echo "NOTE: Singularity HF repo currently ships ref2va (Ref2V) checkpoints primarily."
echo "      For FL2VA (T2V/I2V) pull official/community FL2VA from ${COMPANION_REPO}"
echo "      (e.g. minimax_h3_fl2va_pruned_int8_convrot.safetensors) into diffusion_models/."
