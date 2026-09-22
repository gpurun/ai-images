# =============================================================================
# Product: Qwen-Image-2.1 ComfyUI - 48GB variant
# Full BF16, native 2K resolution
# =============================================================================

ARG BASE_IMAGE=engine/comfyui:v0.37.0
FROM ${BASE_IMAGE}

ENV VARIANT=48g \
    COMFYUI_PORT=8188 \
    WEIGHTS_ROOT=/models \
    MODEL_PATH=/models \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    QUANT_MODE=bf16 \
    DEFAULT_WIDTH=2048 \
    DEFAULT_HEIGHT=2048

COPY ../_qwen-image-21-shared/download_weights.sh /usr/local/bin/download_weights.sh
COPY ../_qwen-image-21-shared/entrypoint-comfyui.sh /usr/local/bin/entrypoint-product.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint-product.sh

RUN mkdir -p /models /output /input \
    && mkdir -p /opt/ComfyUI/models/checkpoints \
               /opt/ComfyUI/models/diffusion_models

EXPOSE 8188
WORKDIR /opt/ComfyUI

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint-product.sh"]
CMD ["serve"]
