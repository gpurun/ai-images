# syntax=docker/dockerfile:1
ARG ENGINE=sglang
ARG REGISTRY=
ARG REPO=
ARG TAG=latest
FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-qwen3-8-27b-${TAG} AS engine
FROM engine
LABEL org.opencontainers.image.title="Qwen3-8-27B" \
      org.opencontainers.image.description="Qwen3-8-27B (8B/27B context-aware, FP8/W4A16 adaptable) serving image (SGLang/vLLM selectable)" \
      org.opencontainers.image.source="https://huggingface.co/Qwen" \
      org.opencontainers.image.vendor="ai-images" \
      ai-images.model="Qwen/Qwen3-8B" \
      ai-images.served-model-name="Qwen3-8B" \
      ai-images.engine="${ENGINE}"
WORKDIR /workspace
CMD []
