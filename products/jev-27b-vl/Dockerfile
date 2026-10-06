# syntax=docker/dockerfile:1
ARG ENGINE=vllm
ARG REGISTRY=
ARG REPO=
ARG TAG=latest
FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-jev-27b-vl-${TAG} AS engine
FROM engine
LABEL org.opencontainers.image.title="JEV-27B-VL" \
      org.opencontainers.image.description="JEV-27B-VL (Qwen3.8-27B + System 1 decision head, text + vision, up to 256 options) serving image for 2-GPU / 4-GPU TP deployment (vLLM, POST /v1/decide)" \
      org.opencontainers.image.source="https://huggingface.co/autotrust/JEV-27B-VL" \
      org.opencontainers.image.vendor="ai-images" \
      ai-images.model="autotrust/JEV-27B-VL" \
      ai-images.served-model-name="autotrust/JEV-27B-VL" \
      ai-images.engine="${ENGINE}"
WORKDIR /workspace
CMD []
