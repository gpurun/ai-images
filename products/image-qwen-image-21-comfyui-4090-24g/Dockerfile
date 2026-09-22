# =============================================================================
# Product: Qwen-Image-2.1 ComfyUI - 4090 24GB variant
# FP8/GGUF quantized for 24GB VRAM, 1024x1024 default
# =============================================================================

ARG BASE_IMAGE=engine/comfyui:v0.37.0
FROM ${BASE_IMAGE}

ENV VARIANT=4090-24g \
    COMFYUI_PORT=8188 \
    WEIGHTS_ROOT=/models \
    MODEL_PATH=/models \
    AUTO_DOWNLOAD_WEIGHTS=0 \
    QUANT_MODE=fp8 \
    DEFAULT_WIDTH=1024 \
    DEFAULT_HEIGHT=1024

# Install ComfyUI-GGUF for quantized model support
RUN cd /opt/ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && \
    python -m pip install -r requirements.txt || true

COPY _qwen-image-21-shared/download_weights.sh /usr/local/bin/download_weights.sh
COPY _qwen-image-21-shared/entrypoint-comfyui.sh /usr/local/bin/entrypoint-product.sh
RUN chmod +x /usr/local/bin/download_weights.sh /usr/local/bin/entrypoint-product.sh

RUN mkdir -p /models /output /input \
    && mkdir -p /opt/ComfyUI/models/checkpoints \
               /opt/ComfyUI/models/diffusion_models

EXPOSE 8188
WORKDIR /opt/ComfyUI

VOLUME ["/models", "/output", "/input"]

ENTRYPOINT ["/usr/local/bin/entrypoint-product.sh"]
CMD ["serve"]
