# =============================================================================
# Base: Python 3.12 + PyTorch 2.6 (cu128) on CUDA runtime
# Layer-cache friendly: system packages -> Python -> torch (heavy, rare change)
# =============================================================================

ARG BASE_IMAGE=base/cuda-runtime:cu128
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION=3.12
ARG TORCH_VERSION=2.6.0
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

# --- PyTorch 2.6.x with CUDA 12.8 wheels (official index) ---
RUN python -m pip install \
        torch==${TORCH_VERSION} \
        torchvision \
        torchaudio \
        --index-url ${TORCH_INDEX_URL}

WORKDIR /workspace

CMD ["python"]
