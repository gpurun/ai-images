# DeepSeek-V4.1-Flash

本产品目录提供 `deepseek-ai/DeepSeek-V4.1`（671B MoE + MLA）的容器化部署，默认服务名 `DeepSeek-V4.1-Flash`，支持 **SGLang** 和 **vLLM** 两种推理引擎。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `deepseek-ai/DeepSeek-V4.1` |
| Served Name | `DeepSeek-V4.1-Flash` |
| 架构 | `DeepseekV4ForCausalLM`（MoE + MLA） |
| 参数规模 | 671B Total / ~37B Active per token |
| 精度 | 原生 FP8（W8A8-FP8） |
| 上下文长度 | 128K（默认），支持 256K ~ 1M（按显存调参） |
| MTP | 原生支持 Multi-Token Prediction（可选开启） |
| License | MIT |

## 2. GPU 卡型、数量及硬件要求

FP8 权重约 `340 ~ 350 GiB`。

### 推荐配置

| GPU 型号 | 架构 | 显存（单卡） | 推荐数量 | 并行方式 | KV Cache Dtype | 备注 |
|---|---|---|---|---|---|---|
| NVIDIA GB200 / B200 | SM100 | 180GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 最佳性能，适合 512K–1M 长上下文 |
| NVIDIA H200 | SM90 | 141GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 主流生产推荐配置 |
| NVIDIA H100 | SM90 | 80GB | **8 卡** | TP=8, EP=8 | fp8_e4m3 | 可稳定跑 256K–512K，1M 需收紧批次与并发 |

推荐：`8× H200 141GB`（TP8 + EP8）+ FP8 KV Cache。

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 16 核以上（推荐 32 核+） | 长上下文 Prefill 对 CPU 有开销 |
| 内存（RAM） | >= 128 GB（推荐 256 GB） | 预加载模型与请求队列 |
| 系统盘 | >= 100 GB（可用） | 容器镜像、日志 |
| 数据盘（模型缓存） | >= 400 GB（可用） | HuggingFace 缓存约 340–350GB |
| 共享内存（SHM） | >= 128 GB | `--shm-size=128g` |
| PCIe/NVLink | PCIe 5.0 x16 或 NVLink/InfiniBand | 跨卡通信 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 经生产环境验证较多 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 及 FP8 KV Cache |
| CUDA | 12.8.x | 基于 `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04` 构建 |
| Docker | >= 24.0 | 推荐最新版 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定（高速） | 首次下载模型约 350GB |

## 4. 快速开始

```bash
cd products/deepseek-v4.1-flash
cp .env.example .env
# 编辑 .env 按需配置 HF_TOKEN、GPU 等
```

预先下载模型（推荐）：

```bash
huggingface-cli download deepseek-ai/DeepSeek-V4.1 \
  --local-dir ~/.cache/huggingface/models--deepseek-ai--DeepSeek-V4.1 \
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
# SGLang
curl http://127.0.0.1:30000/v1/models

# vLLM
curl http://127.0.0.1:8000/v1/models
```

## 7. 注意事项

- 671B MoE 必须开启 EP（TP8+EP8 推荐）
- SGLang 推荐 `flashmla` + `deep_gemm`；vLLM 推荐 `FLASH_ATTN_MLA` + `PIECEWISE` CUDA Graphs
- 1M 上下文+高并发容易出现 CUDA Graph Capture OOM，建议降低并发或 Prefill 批次
- 生产环境建议锁定引擎（sglang/sgl-kernel/vllm）的 commit SHA 以保证可复现性
