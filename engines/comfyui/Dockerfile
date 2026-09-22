# =============================================================================
# Engine: ComfyUI (>= 0.30.0) — video/image workflows
# FROM python-ml base (Python 3.12 + PyTorch cu128 already installed)
# =============================================================================

ARG BASE_IMAGE=base/python-ml:cu128-py312
FROM ${BASE_IMAGE}

ARG COMFYUI_REF=v0.37.0

ENV DEBIAN_FRONTEND=noninteractive

# ffmpeg for video encode/decode in ComfyUI workflows
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Clone ComfyUI at pinned ref; install requirements without reinstalling torch.
RUN git clone --depth 1 --branch "${COMFYUI_REF}" \
        https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
    && cd /opt/ComfyUI \
    && grep -vE '^(torch|torchvision|torchaudio)([=<>!]|$)' requirements.txt \
        > /tmp/comfy-req.txt \
    && python -m pip install -r /tmp/comfy-req.txt \
    && rm -f /tmp/comfy-req.txt

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8188
WORKDIR /opt/ComfyUI

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
