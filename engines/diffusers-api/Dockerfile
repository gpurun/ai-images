# =============================================================================
# Engine: Diffusers API server for image generation models
# Thin FastAPI wrapper around diffusers pipelines (e.g. QwenImage21Pipeline)
# Endpoints: /generate (t2i), /edit, /health
# =============================================================================

ARG BASE_IMAGE=base/python-ml:cu128-py312
FROM ${BASE_IMAGE}

# Diffusers + FastAPI + Qwen-Image-2.1 dependencies
# diffusers >= 0.33.0 for QwenImage21Pipeline (check latest)
# accelerate for device offload, safetensors for model loading
RUN python -m pip install \
    "diffusers>=0.33.0" \
    "transformers>=4.47.0" \
    "accelerate>=1.2.0" \
    "safetensors>=0.5.0" \
    "pillow>=11.0.0" \
    "fastapi>=0.115.0" \
    "uvicorn[standard]>=0.32.0" \
    "pydantic>=2.10.0" \
    "pydantic-settings>=2.6.0"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY server.py /opt/diffusers-api/server.py
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000
WORKDIR /opt/diffusers-api

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
