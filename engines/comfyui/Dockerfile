# =============================================================================
# Engine: ComfyUI (>= 0.30.0) — video/image workflows
# FROM python-ml base (Python 3.12 + PyTorch cu128 already installed)
# CRITICAL: Force-reinstall torch trio after ComfyUI deps to prevent ABI breaks
# =============================================================================

ARG BASE_IMAGE=base/python-ml:cu128-py312-torch2.7
FROM ${BASE_IMAGE}

ARG COMFYUI_REF=v0.37.0
ARG TORCH_VERSION=2.7.0
ARG TORCHVISION_VERSION=0.22.0
ARG TORCHAUDIO_VERSION=2.7.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128

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

# CRITICAL: Force-reinstall pinned torch trio to prevent ABI mismatches from transitive deps
# Any ComfyUI or custom node dependency that pulls torch/torchaudio from PyPI will break
RUN python -m pip install --force-reinstall --no-deps \
        torch==${TORCH_VERSION}+cu128 \
        torchvision==${TORCHVISION_VERSION}+cu128 \
        torchaudio==${TORCHAUDIO_VERSION}+cu128 \
        --index-url ${TORCH_INDEX_URL}

# Smoke test: verify torch/torchaudio ABI compatibility + ComfyUI execution path
RUN python -c "import torch, torchaudio; assert 'cu128' in torch.__version__; import sys; sys.path.insert(0, '/opt/ComfyUI'); import execution; print('✓ smoke ok:', torch.__version__, torchaudio.__version__)"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8188
WORKDIR /opt/ComfyUI

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
