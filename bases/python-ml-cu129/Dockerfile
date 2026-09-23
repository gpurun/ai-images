# =============================================================================
# Base: Python 3.12 + PyTorch 2.13.0 (cu129) on CUDA runtime
# Dedicated base for VDN-H3 and other models requiring torch 2.13+/cu129
# =============================================================================

ARG BASE_IMAGE=base/cuda-runtime:cu128
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION=3.12
ARG TORCH_VERSION=2.13.0
ARG TORCHVISION_VERSION=0.28.0
ARG TORCHAUDIO_VERSION=2.13.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu129

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
        git \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        python3-pip \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3 \
    && python -m ensurepip --upgrade || true \
    && python -m pip install --upgrade pip setuptools wheel uv \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# --- PyTorch 2.13.0 + torchvision 0.28.0 + torchaudio 2.13.0 (cu129) ---
# VDN-H3 officially recommends torch 2.13.0+cu129 for optimal FlashAttention 4 support
RUN python -m pip install \
        torch==${TORCH_VERSION} \
        torchvision==${TORCHVISION_VERSION} \
        torchaudio==${TORCHAUDIO_VERSION} \
        --index-url ${TORCH_INDEX_URL}

WORKDIR /workspace

CMD ["python"]
