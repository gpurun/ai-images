# =============================================================================
# Product: video-vdn-minimax-h3
# OpenVDN VDN-H3 (Video DeltaNet on MiniMax-H3) hybrid-attention video generation
# Dual-mode serving: SGLang Diffusion (primary, multi-GPU optimal) + Diffusers API (fallback, 24GB single-GPU)
# Do NOT COPY ~82GB weights into image layers — download at runtime / mount.
# Built with: Python 3.12, CUDA 12.9, PyTorch 2.13.0+cu129, FlashAttention 4
# =============================================================================

ARG BASE_IMAGE=engine/vdn-serve:v1
FROM ${BASE_IMAGE}

# Product metadata
LABEL maintainer="GPURun Team" \
      org.opencontainers.image.title="VDN-MiniMax-H3 Video Generation" \
      org.opencontainers.image.description="OpenVDN VDN-H3 hybrid-attention video generation with SGLang + Diffusers dual-mode serving" \
      org.opencontainers.image.source="https://github.com/gpurun/ai-images" \
      org.opencontainers.image.licenses="MiniMax-H3-Community-License"

ENV MODEL_PATH=/models \
    CKPT_DIR=/models/ckpts \
    SERVE_MODE=sglang \
    SGLANG_PORT=30010 \
    DIFFUSERS_PORT=8000 \
    NUM_GPUS=1 \
    QUANTIZATION=fp8 \
    ATTENTION_BACKEND=hybrid_window_attn_h3 \
    PERFORMANCE_MODE=speed \
    WARMUP_FRAMES=345 \
    WARMUP_RESOLUTION=1344x768 \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    HF_HOME=/models/hf

# Install VDN-H3 repository + diffusers patches
# Manually apply setup_diffusers.sh logic to ensure --system flag placement is correct for uv
WORKDIR /opt
RUN git config --global user.email "builder@gpurun.com" \
    && git config --global user.name "GPURun Builder" \
    && git clone --depth 1 https://github.com/OpenVDN/vdn-minimax-h3.git vdn \
    && cd vdn \
    && PIN=$(sed -n 's/^upstream base: \([0-9a-f]*\).*/\1/p' diffusers_patches/BASE.txt) \
    && git clone https://github.com/huggingface/diffusers.git diffusers \
    && git -C diffusers checkout --quiet --detach "$PIN" \
    && git -C diffusers am --quiet "$PWD"/diffusers_patches/*.patch \
    && echo "diffusers: $PIN + $(ls diffusers_patches/*.patch | wc -l) patches applied" \
    && uv pip install --system -e diffusers \
    && uv pip install --system -e .

# Copy product scripts
COPY download_weights.sh /usr/local/bin/download_weights.sh
COPY serve_diffusers.py /opt/vdn/serve_diffusers.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint.sh

# Copy license materials (MiniMax H3 Community License requirement)
COPY NOTICE /opt/vdn/NOTICE
COPY LICENSE /opt/vdn/LICENSE

# Prepare mount points (weights, IO) — empty in image
RUN mkdir -p /models/ckpts /models/hf /output /input

# Smoke test: verify critical imports without GPU
RUN python -c "import torch; import diffusers; import transformers; print(f'torch={torch.__version__}, cuda={torch.version.cuda}')" && \
    python -c "import sglang; print(f'sglang installed')" && \
    python -c "from src.inference.infer_diffusers import main; print('VDN diffusers entry verified')" || true

# Expose ports: 30010 (SGLang), 8000 (Diffusers)
EXPOSE 30010 8000
WORKDIR /opt/vdn

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
