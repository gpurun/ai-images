# =============================================================================
# Product: Qwen-Image-2.1 Diffusers API - 4090 24GB variant
# FP8/FP16 optimized for 24GB VRAM, 1024x1024 default resolution
# =============================================================================

ARG BASE_IMAGE=engine/diffusers-api:v1
FROM ${BASE_IMAGE}

ENV VARIANT=4090-24g \
    MODEL_PATH=/models \
    WEIGHTS_ROOT=/models \
    PORT=8000 \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    TORCH_DTYPE=fp16 \
    DEFAULT_WIDTH=1024 \
    DEFAULT_HEIGHT=1024 \
    ENABLE_CPU_OFFLOAD=1

COPY ../_qwen-image-21-shared/download_weights.sh /usr/local/bin/download_weights.sh
COPY ../_qwen-image-21-shared/entrypoint-diffusers.sh /usr/local/bin/entrypoint-product.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint-product.sh

RUN mkdir -p /models /output /input

EXPOSE 8000
WORKDIR /opt/diffusers-api

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint-product.sh"]
CMD ["serve"]
