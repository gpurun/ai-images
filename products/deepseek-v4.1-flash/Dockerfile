# syntax=docker/dockerfile:1
ARG ENGINE=sglang
ARG REGISTRY=
ARG REPO=
ARG TAG=latest

FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-deepseek-v4.1-flash-${TAG} AS engine

FROM engine

LABEL org.opencontainers.image.title="DeepSeek-V4.1-Flash" \
      org.opencontainers.image.description="DeepSeek-V4.1-Flash (671B MoE, MLA, FP8) serving image (SGLang/vLLM selectable)" \
      org.opencontainers.image.source="https://github.com/deepseek-ai/DeepSeek-V4.1" \
      org.opencontainers.image.vendor="ai-images" \
      ai-images.model="deepseek-ai/DeepSeek-V4.1" \
      ai-images.served-model-name="DeepSeek-V4.1-Flash" \
      ai-images.engine="${ENGINE}"

WORKDIR /workspace
CMD []
