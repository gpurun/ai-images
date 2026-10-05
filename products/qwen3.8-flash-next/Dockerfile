# syntax=docker/dockerfile:1
ARG ENGINE=sglang
ARG REGISTRY=
ARG REPO=
ARG TAG=latest
FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-qwen3.8-flash-next-${TAG} AS engine
FROM engine
LABEL org.opencontainers.image.title="Qwen3.8-Flash-Next" \
      org.opencontainers.image.description="Qwen3.8-Flash-Next (FP8/efficient) serving image (SGLang/vLLM/Ollama selectable)" \
      org.opencontainers.image.source="https://huggingface.co/Qwen/Qwen3.8-Flash-Next" \
      org.opencontainers.image.vendor="ai-images" \
      ai-images.model="Qwen/Qwen3.8-Flash-Next" \
      ai-images.served-model-name="Qwen3.8-Flash-Next" \
      ai-images.engine="${ENGINE}"
WORKDIR /workspace
CMD []
