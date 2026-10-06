# syntax=docker/dockerfile:1
ARG ENGINE=vllm
ARG REGISTRY=
ARG REPO=
ARG TAG=latest
FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-jev-9b-${TAG} AS engine
FROM engine
LABEL org.opencontainers.image.title="JEV-9B" \
      org.opencontainers.image.description="JEV-9B (Qwen3.5-9B backbone + System 1 decision head, text + vision) serving image on single-GPU RTX 4090 (vLLM, POST /v1/decide)" \
      org.opencontainers.image.source="https://huggingface.co/autotrust/JEV-9B" \
      org.opencontainers.image.vendor="ai-images" \
      ai-images.model="autotrust/JEV-9B" \
      ai-images.served-model-name="autotrust/JEV-9B" \
      ai-images.engine="${ENGINE}"
WORKDIR /workspace
CMD []
