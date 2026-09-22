# =============================================================================
# Product: video-minimax-h3-singularity
# MiniMax-H3 community fine-tune (WarmBloodAban) on ComfyUI engine.
# Do NOT COPY multi-GB weights into image layers — download at runtime / mount.
# Built with: Python 3.12, CUDA 12.8, PyTorch 2.7.0+cu128, ComfyUI v0.37.0-torch2.7
# =============================================================================

ARG BASE_IMAGE=engine/comfyui:v0.37.0-torch2.7
FROM ${BASE_IMAGE}

ENV COMFYUI_PORT=8188 \
    WEIGHTS_ROOT=/models \
    HF_REPO=WarmBloodAban/Minimax-h3_Singularity \
    DIFFUSION_FILE=Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    HF_HOME=/models/hf

# huggingface-cli / hf for optional weight download
RUN python -m pip install "huggingface_hub[cli]"

COPY download_weights.sh /usr/local/bin/download_weights.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint.sh

# Prepare mount points (weights, IO) — empty in image
RUN mkdir -p /models /output /input \
    && mkdir -p /opt/ComfyUI/models/diffusion_models \
               /opt/ComfyUI/models/text_encoders \
               /opt/ComfyUI/models/vae \
               /opt/ComfyUI/output \
               /opt/ComfyUI/input

EXPOSE 8188
WORKDIR /opt/ComfyUI

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
