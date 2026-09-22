# =============================================================================
# Product: Qwen-Image-2.1 Diffusers API - RTX 5090 variant
# BF16 optimized for RTX 5090 (~32GB VRAM), 1.5K default resolution
# =============================================================================

ARG BASE_IMAGE=engine/diffusers-api:v1
FROM ${BASE_IMAGE}

ENV VARIANT=5090 \
    MODEL_PATH=/models \
    WEIGHTS_ROOT=/models \
    PORT=8000 \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    TORCH_DTYPE=bf16 \
    DEFAULT_WIDTH=1536 \
    DEFAULT_HEIGHT=1536 \
    ENABLE_CPU_OFFLOAD=0

COPY _qwen-image-21-shared/download_weights.sh /usr/local/bin/download_weights.sh
COPY _qwen-image-21-shared/entrypoint-diffusers.sh /usr/local/bin/entrypoint-product.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint-product.sh

RUN mkdir -p /models /output /input

EXPOSE 8000
WORKDIR /opt/diffusers-api

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint-product.sh"]
CMD ["serve"]
