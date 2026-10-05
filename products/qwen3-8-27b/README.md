# Qwen3-8-27B（部署模板）

本目录为 Qwen3 系列（8B/14B/32B 等）提供统一的 SGLang/vLLM 容器化部署模板。默认示例使用 `Qwen/Qwen3-8B`，可通过 `.env` 中的 `MODEL_PATH`、`SERVED_MODEL_NAME`、`TP_SIZE` 灵活切换模型及并行配置。

## 1. 模型信息（示例：Qwen3-8B）

| 字段 | 值（示例） |
|---|---|
| Model ID | `Qwen/Qwen3-8B`（可替换为 `Qwen/Qwen3-14B`、`Qwen/Qwen3-32B` 等） |
| Served Name | `Qwen3-8B`（可自定义） |
| 架构 | Transformer（Dense/MoE 视具体变体） |
| 上下文长度 | 131072（默认模板） |
| 精度 | 建议 FP8/W4A16（按显存选择） |
| License | Apache-2.0 |

## 2. GPU 卡型、数量及硬件要求

以下按常用 Qwen3 变体给出参考。实际以 `.env` 中 `TP_SIZE` 为准。

### 推荐配置参考

| 模型 | GPU 型号 | 显存（单卡） | 推荐数量 | 并行方式 | 说明 |
|---|---|---|---|---|---|
| Qwen3-8B（FP8） | RTX 4090/5070Ti 以上、H100/H200/B200 | >= 16GB（推荐 >= 24GB） | **1 卡** | TP=1 | 单卡即可满足日常推理 |
| Qwen3-14B（FP8） | H100 80GB、H200 141GB、B200、RTX PRO 6000 | >= 32GB（推荐 >= 48GB） | **1 卡**（或 2 卡 TP=2） | TP=1 或 TP=2 | 视上下文与并发而定 |
| Qwen3-32B（FP8） | H100 80GB、H200 141GB、B200、GB200 | >= 64GB（推荐 >= 80GB） | **2 卡**（推荐）或 **4 卡**（高并发） | TP=2 或 TP=4 | 建议 TP>=2 获得更好吞吐 |

> 提示：若使用 W4A16 量化，可适当降低显存需求（约节省 30–40%）。

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 8–16 核以上（推荐 16 核+） | 一般场景足够 |
| 内存（RAM） | >= 32 GB（14B 推荐 >= 48GB，32B 推荐 >= 64GB） | 取决于模型与上下文 |
| 系统盘 | >= 40 GB（可用） | 镜像与日志 |
| 数据盘（模型缓存） | >= 20–70 GB（可用） | 8B FP8 约 15–20GB，14B 约 30GB，32B 约 65GB |
| 共享内存（SHM） | >= 32 GB（推荐 64 GB） | 高并发建议更大 |
| PCIe/NVLink | PCIe 4.0+ 即可，NVLink 更佳（多卡场景） | 多卡 TP 场景通信需求随卡数增加 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 通用 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 |
| CUDA | 12.8.x | 本模板基于 CUDA 12.8.1 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定 | 下载模型需网络连接 |

## 4. 快速开始

```bash
cd products/qwen3-8-27b
cp .env.example .env
# 编辑 .env：MODEL_PATH、SERVED_MODEL_NAME、TP_SIZE、CONTEXT_LENGTH 等
vim .env
```

按需下载模型：

```bash
huggingface-cli download Qwen/Qwen3-8B \
  --local-dir ~/.cache/huggingface/models--Qwen--Qwen3-8B \
  --local-dir-use-symlinks False
```

## 5. 启动

### SGLang（Docker Compose）

```bash
docker compose -f docker-compose.sglang.yaml up -d --build
```

### vLLM（Docker Compose）

```bash
docker compose -f docker-compose.vllm.yaml up -d --build
```

### Ollama（Docker Compose，GGUF 长上下文）

```bash
# 默认：FlashAttention + q8_0 KV Cache + 128K 上下文 + 模型常驻
docker compose -f docker-compose.ollama.yaml up -d --build
```

默认拉取 `qwen3:8b`（模板默认 8B）；切换 14B/32B 时在 `.env` 同步修改 `OLLAMA_MODEL` 与 `OLLAMA_PULL`（如 `qwen3:14b`、`qwen3:32b`，或 `hf.co/unsloth/Qwen3-8B-GGUF` 等）：

```bash
OLLAMA_PULL=qwen3:8b AUTO_DOWNLOAD_WEIGHTS=1 \
  docker compose -f docker-compose.ollama.yaml run --rm qwen3-8-27b-ollama download
```

## 6. 验证

```bash
# SGLang（端口 30000）
curl http://127.0.0.1:30000/v1/models
# vLLM（端口 8000）
curl http://127.0.0.1:8000/v1/models
# Ollama（端口 11434）
curl http://127.0.0.1:11434/api/version
curl http://127.0.0.1:11434/v1/models
```

## 7. 使用提示

- 单卡 8B：默认 `TP_SIZE=1` 即可
- 多卡 14B/32B：按实际卡数设置 `TP_SIZE`（常用 2、4）
- 上下文：131072 已适配模板，超长需结合显存微调 `max-num-seqs`、`max-prefill-tokens`
- 推理后端：SGLang 默认启用 `deep_gemm`（如可用），vLLM 使用 `FLASH_ATTN`
- Ollama：改 `.env` 中 `OLLAMA_MODEL`/`OLLAMA_PULL` 即可切换 8B/14B/32B GGUF；`q8_0` KV Cache 下 131072 上下文显存开销约为 fp8 KV 的 1.5～2 倍（`OLLAMA_KV_CACHE_TYPE` 可按卡型调整）
