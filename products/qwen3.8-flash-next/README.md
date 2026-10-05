# Qwen3.8-Flash-Next

模型地址：[https://huggingface.co/Qwen/Qwen3.8-Flash-Next](https://huggingface.co/Qwen/Qwen3.8-Flash-Next)

本产品按当前项目标准提供 **SGLang** 与 **vLLM** 两种引擎的容器化部署方案，面向高效推理场景。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `Qwen/Qwen3.8-Flash-Next` |
| Served Name | `Qwen3.8-Flash-Next`（可在 `.env` 中修改） |
| 架构 | Transformer |
| 参数规模 | 8B |
| 精度 | FP8（推荐部署精度） |
| 上下文长度 | 131072（默认） |
| License | Apache-2.0 |

## 2. GPU 卡型、数量及硬件要求

### 推荐配置

| GPU 型号 | 显存（单卡） | 推荐数量 | 并行方式 | 说明 |
|---|---|---|---|---|
| NVIDIA RTX 4090 / 5080 / 5090 | 24GB / 32GB / 32GB | **1 卡** | TP=1 | 桌面端高性价比，单卡足够 |
| NVIDIA H100 80GB / H200 141GB / B200 / GB200 | 80GB+ | **1 卡** | TP=1 | 生产环境更高吞吐与稳定性 |
| 多卡场景（可选） | >= 16GB | **2 卡** | TP=2 | 极高并发或定制化场景 |

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 8–16 核以上 | 日常推理足够 |
| 内存（RAM） | >= 32 GB（推荐 48 GB） | 加载模型与并发请求 |
| 系统盘 | >= 40 GB（可用） | 容器镜像、日志 |
| 数据盘（模型缓存） | >= 20 GB（可用） | 模型权重缓存（FP8 约 10–16GB，建议预留余量） |
| 共享内存（SHM） | >= 32 GB（推荐 64 GB） | 高并发时建议增大 |
| PCIe | PCIe 4.0+ | 单卡场景无特殊要求，多卡建议更高带宽 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 稳定 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 |
| CUDA | 12.8.x | 基于 `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04` 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定 | 下载模型约 10–20GB |

## 4. 快速开始

```bash
cd products/qwen3.8-flash-next
cp .env.example .env
# 根据 GPU 数量调整 TP_SIZE（默认 1）
vim .env
```

下载模型：

```bash
huggingface-cli download Qwen/Qwen3.8-Flash-Next \
  --local-dir ~/.cache/huggingface/models--Qwen--Qwen3.8-Flash-Next \
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

## 6. 验证

```bash
# SGLang（端口 30000）
curl http://127.0.0.1:30000/v1/models
# vLLM（端口 8000）
curl http://127.0.0.1:8000/v1/models
```

## 7. 注意事项

- 单卡首选：8B Flash-Next 模型单卡（24GB+）即可高效运行，默认 `TP_SIZE=1`
- KV Cache：默认模板使用 `fp8_e4m3` KV Cache（若显存极为紧张可按需改为 `auto`/`bf16` 并实测）
- 推理后端：SGLang 启用 `deep_gemm`，vLLM 使用 `FLASH_ATTN`，均适配 8B 场景
