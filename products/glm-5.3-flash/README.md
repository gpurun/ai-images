# GLM-5.3-Flash

`zai-org/GLM-5.3-Flash`（320B Total / 18B Active，MoE，KDA + DSA 混合注意力，FP8）。首个 GLM 系列原生多模态模型，针对超低成本推理优化。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `zai-org/GLM-5.3-Flash` |
| Served Name | `GLM-5.3-Flash` |
| 架构 | `Glm5NextForConditionalGeneration`（MoE + 混合注意力 KDA/DSA） |
| 参数规模 | 320B Total / 18B Active per token |
| 精度 | 原生 FP8（W8A8-FP8） |
| 上下文长度 | 1,048,576（1M） |
| License | MIT |

## 2. GPU 卡型、数量及硬件要求

FP8 权重约 `306 ~ 310 GiB`，运行时需预留 KV Cache。

### 推荐配置

| GPU 型号 | 架构 | 显存（单卡） | 推荐数量 | 并行方式 | KV Cache Dtype | 备注 |
|---|---|---|---|---|---|---|
| NVIDIA GB200 / B200 | SM100 | 180GB | **4 卡** | TP=4, EP=4 | fp8_e4m3 | 最佳，稳定跑满 1M 上下文 |
| NVIDIA H200 / H100 | SM90 | 141GB / 80GB | **4 卡** | TP=4, EP=4 | fp8_e4m3 | 主流推荐（80GB×4 可跑 512K–1M，视并发而定） |
| NVIDIA RTX PRO 6000（Blackwell Pro） | SM120 | 96GB | **4 卡** | TP=4, EP=4 | fp8_e4m3 | 需配合最新 SGLang/vLLM 构建 |
| NVIDIA DGX Spark GB10 | SM121 | 128GB（双机） | **2 卡（TP2）** | TP=2, EP=2 | fp8_e4m3 | 桌面级场景，建议配合 vLLM 路径 |

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 16 核以上（推荐 24–32 核） | 长上下文处理 |
| 内存（RAM） | >= 96 GB（推荐 128 GB） | 模型加载与请求处理 |
| 系统盘 | >= 80 GB（可用） | 镜像与日志 |
| 数据盘（模型缓存） | >= 350 GB（可用） | HuggingFace 缓存（约 306–310GB） |
| 共享内存（SHM） | >= 64 GB（推荐 128 GB） | Compose 中设置 `shm_size` |
| PCIe/NVLink | 推荐 NVLink 或 PCIe 5.0 | 跨卡通信更顺畅 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 稳定性较好 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 与 FP8 |
| CUDA | 12.8.x | 基于 `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04` 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定 | 首次下载模型约 300+GB |

## 4. 快速开始

```bash
cd products/glm-5.3-flash
cp .env.example .env
# 按硬件调整 TP_SIZE/EP_SIZE（4卡推荐 TP4+EP4）
```

```bash
huggingface-cli download zai-org/GLM-5.3-Flash \
  --local-dir ~/.cache/huggingface/models--zai-org--GLM-5.3-Flash \
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

## 7. 关键说明

- SGLang：推荐开启 `deep_gemm` + `trtllm`（DSA Prefill/Decode）以跑通混合注意力（KDA+DSA）
- vLLM：使用 `FLASH_ATTN_MLA_SPARSE` Attention Backend 配合最新构建以获得 Sparse MLA/NoPE 路径支持
- 1M 长上下文：需按显存调整并发、`max-prefill-tokens`、`chunked-prefill-size`
