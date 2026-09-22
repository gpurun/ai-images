# =============================================================================
# Engine: SGLang inference runtime
# FROM python-ml base (Python 3.12 + PyTorch cu128)
# =============================================================================

ARG BASE_IMAGE=base/python-ml:cu128-py312
FROM ${BASE_IMAGE}

ARG SGLANG_VERSION=0.4.6

RUN python -m pip install "sglang[all]==${SGLANG_VERSION}" \
    || python -m pip install "sglang==${SGLANG_VERSION}"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 30000
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
