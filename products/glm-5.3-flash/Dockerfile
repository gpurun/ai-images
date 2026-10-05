# syntax=docker/dockerfile:1
ARG ENGINE=sglang
ARG REGISTRY=
ARG REPO=
ARG TAG=latest
FROM ${REGISTRY}${REPO}engines/llm:${ENGINE}-glm-5.3-flash-${TAG} AS engine
FROM engine
LABEL org.opencontainers.image.title="GLM-5.3-Flash" org.opencontainers.image.description="GLM-5.3-Flash (320B MoE, KDA+DSA Hybrid Attention, FP8) serving image (SGLang/vLLM selectable)" org.opencontainers.image.source="https://huggingface.co/zai-org/GLM-5.3-Flash" org.opencontainers.image.vendor="ai-images" ai-images.model="zai-org/GLM-5.3-Flash" ai-images.served-model-name="GLM-5.3-Flash" ai-images.engine="${ENGINE}"
WORKDIR /workspace
CMD []
