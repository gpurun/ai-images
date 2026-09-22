# =============================================================================
# Base: Python 3.12 + PyTorch 2.7.0 (cu128) on CUDA runtime
# Layer-cache friendly: system packages -> Python -> torch (heavy, rare change)
# CRITICAL: torch/torchvision/torchaudio must be ABI-compatible (same versions)
# =============================================================================

ARG BASE_IMAGE=base/cuda-runtime:cu128
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION=3.12
ARG TORCH_VERSION=2.7.0
ARG TORCHVISION_VERSION=0.22.0
ARG TORCHAUDIO_VERSION=2.7.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# --- System packages + Python 3.12 (deadsnakes on Ubuntu 22.04) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        build-essential \
        gnupg \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        python3-pip \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3 \
    && python -m ensurepip --upgrade || true \
    && python -m pip install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# --- PyTorch 2.7.0 + torchvision 0.22.0 + torchaudio 2.7.0 (ABI-compatible trio) ---
# Install pinned versions from cu128 index to prevent ABI mismatches
RUN python -m pip install \
        torch==${TORCH_VERSION}+cu128 \
        torchvision==${TORCHVISION_VERSION}+cu128 \
        torchaudio==${TORCHAUDIO_VERSION}+cu128 \
        --index-url ${TORCH_INDEX_URL}

WORKDIR /workspace

CMD ["python"]
