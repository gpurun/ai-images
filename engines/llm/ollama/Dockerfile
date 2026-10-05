# syntax=docker/dockerfile:1
# =============================================================================
# Engine: Ollama GGUF serving — performance + long-context defaults
# Base: ollama/ollama (CUDA runtime, no Python base required)
# =============================================================================
ARG OLLAMA_VERSION=0.35.1
FROM ollama/ollama:${OLLAMA_VERSION}

# Performance: FlashAttention + q8_0 quantized KV cache (≈1/4 KV memory of f16,
# required to sustain long contexts inside the same VRAM budget)
ENV OLLAMA_HOST=0.0.0.0:11434 \
    OLLAMA_MODELS=/models/ollama \
    OLLAMA_FLASH_ATTENTION=1 \
    OLLAMA_KV_CACHE_TYPE=q8_0 \
    OLLAMA_CONTEXT_LENGTH=131072 \
    OLLAMA_NUM_PARALLEL=4 \
    OLLAMA_MAX_LOADED_MODELS=1 \
    OLLAMA_KEEP_ALIVE=-1

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 11434
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
