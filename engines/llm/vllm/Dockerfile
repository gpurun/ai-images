# =============================================================================
# Engine: vLLM inference server
# FROM python-ml base (Python 3.12 + PyTorch cu128)
# =============================================================================

ARG BASE_IMAGE=base/python-ml:cu128-py312
FROM ${BASE_IMAGE}

ARG VLLM_VERSION=0.8.5

RUN apt-get update && apt-get install -y --no-install-recommends \
        libnuma1 \
    && rm -rf /var/lib/apt/lists/* \
    && python -m pip install "vllm==${VLLM_VERSION}"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
