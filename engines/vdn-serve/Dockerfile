# =============================================================================
# Engine: VDN (Video DeltaNet) Serve - SGLang Diffusion + Diffusers
# Optimized inference stack for VDN-MiniMax-H3 hybrid attention video generation
# FROM python-ml-cu129 base (Python 3.12 + PyTorch 2.13.0+cu129)
# =============================================================================

ARG BASE_IMAGE=base/python-ml-cu129:cu129-py312-torch2.13
FROM ${BASE_IMAGE}

# Core dependencies for VDN-H3 inference
# - FlashAttention 4 (optional, for Hopper/Blackwell; gracefully falls back on Ampere/Ada/RTX 50)
# - SGLang with diffusion support (fastest serving path)
# - Diffusers + patches (fallback path, 24GB-friendly)
# - torchao for fp8 quantization
ENV DEBIAN_FRONTEND=noninteractive

# Install uv for faster package resolution
RUN python -m pip install -U uv

# Install FlashAttention 4 (prerelease) - optional for sm90+ (Hopper/Blackwell)
# On Ampere/Ada/consumer Blackwell this install succeeds but the kernels are not used
RUN python -m pip install --prerelease=allow flash-attn-4==4.0.0b26 || \
    echo "FlashAttention 4 install skipped (optional for Ampere/Ada/RTX 50)"

# Core VDN dependencies from pyproject.toml
RUN uv pip install --system \
    triton==3.7.1 \
    transformers==5.15.0 \
    accelerate==1.14.0 \
    torchao==0.18.0 \
    peft==0.20.0 \
    safetensors==0.8.0 \
    "huggingface_hub>=1.27.0" \
    omegaconf==2.3.1 \
    pyyaml==6.0.3 \
    einops==0.8.2 \
    "numpy>=2.5,<3" \
    "pillow>=12.0" \
    av==18.1.0 \
    tqdm \
    fastapi \
    uvicorn

# Install SGLang with diffusion support (VDN-H3 native serving)
RUN uv pip install --system --prerelease=allow "sglang[diffusion]"

# Install upstream diffusers (will be patched in product layer with VDN-specific ModularPipeline support)
RUN uv pip install --system diffusers

# Prepare workspace
WORKDIR /workspace

CMD ["python"]
