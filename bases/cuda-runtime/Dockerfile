# =============================================================================
# Base: CUDA runtime with minimal system tools
# Stack: CUDA 12.8 + cuDNN (Ubuntu 22.04)
# =============================================================================

ARG CUDA_IMAGE_TAG=12.8.1-cudnn-devel-ubuntu22.04
FROM nvidia/cuda:${CUDA_IMAGE_TAG}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /workspace

CMD ["/bin/bash"]
