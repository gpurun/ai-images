# GLM-5.3

`zai-org/GLM-5.3`（744B Total / 40B Active，MoE，FP8），面向复杂系统工程与长时 Agentic 任务的大规模模型。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `zai-org/GLM-5.3` |
| Served Name | `GLM-5.3` |
| 架构 | `Glm5NextForConditionalGeneration`（MoE） |
| 参数规模 | 744B Total / 40B Active per token |
| 精度 | 原生 FP8（W8A8-FP8） |
| 上下文长度 | 128K~1M（按硬件与调参） |
| License | MIT |

## 2. GPU 卡型、数量及硬件要求

FP8 权重较大，运行时需充足显存。

### 推荐配置

| GPU 型号 | 架构 | 显存（单卡） | 推荐数量 | 并行方式 | KV Cache Dtype | 备注 |
|---|---|---|---|---|---|---|
| NVIDIA GB200 / B200 | SM100 | 180GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 顶级配置，适合高并发+长上下文 |
| NVIDIA H200 | SM90 | 141GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 主流推荐 |
| NVIDIA H100 | SM90 | 80GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 可用，需合理控制批次 |

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 32 核以上 | 推荐多核提升 Prefill 稳定性 |
| 内存（RAM） | >= 192 GB（推荐 256 GB） | 模型加载与并发请求 |
| 系统盘 | >= 120 GB（可用） | 容器镜像、日志 |
| 数据盘（模型缓存） | >= 600 GB（可用） | HuggingFace 缓存（FP8 约 500GB+，建议预留余量） |
| 共享内存（SHM） | >= 128 GB | 设置 `shm_size=128g` |
| 互联 | 强烈推荐 NVLink/InfiniBand | 671–744B 级跨卡通信较重 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 生产常用 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 |
| CUDA | 12.8.x | 本镜像构建基于 CUDA 12.8.1 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定（高速） | 首次下载模型需较长时间 |

## 4. 快速开始

```bash
cd products/glm-5.3
cp .env.example .env
# 744B 推荐 TP8+EP8
```

```bash
huggingface-cli download zai-org/GLM-5.3 \
  --local-dir ~/.cache/huggingface/models--zai-org--GLM-5.3 \
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

- 744B FP8：显存与带宽要求较高，推荐 8×141GB 以上配置
- EP 必须开启：MoE 规模较大，建议 `TP8 + EP8`
- 长上下文：1M 场景需降低并发、限制 `max-prefill-tokens`，避免 Prefill OOM
