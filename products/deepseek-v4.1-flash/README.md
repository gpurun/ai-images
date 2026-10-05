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

## 2. 硬件要求

FP8 权重约 `340 ~ 350 GiB`。

| GPU | 推荐 TP/EP | KV Cache Dtype |
|---|---|---|
| GB200/B200 (SM100) | TP=8, EP=8 | fp8_e4m3 |
| H200 (SM90, 141GB) | TP=8, EP=8 | fp8_e4m3 |
| H100 (SM90, 80GB) | TP=8, EP=8 | fp8_e4m3 |

推荐：`8× H200 141GB`（TP8 + EP8）+ FP8 KV Cache。

## 3. 快速开始

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

## 4. 启动

### SGLang（Docker Compose）

```bash
docker compose -f docker-compose.sglang.yaml up -d --build
```

### vLLM（Docker Compose）

```bash
docker compose -f docker-compose.vllm.yaml up -d --build
```

## 5. 验证

```bash
# SGLang
curl http://127.0.0.1:30000/v1/models

# vLLM
curl http://127.0.0.1:8000/v1/models
```

## 6. 注意事项

- 671B MoE 必须开启 EP（TP8+EP8 推荐）
- SGLang 推荐 `flashmla` + `deep_gemm`；vLLM 推荐 `FLASH_ATTN_MLA` + `PIECEWISE` CUDA Graphs
- 1M 上下文+高并发容易出现 CUDA Graph Capture OOM，建议降低并发或 Prefill 批次
- 生产环境建议锁定引擎（sglang/sgl-kernel/vllm）的 commit SHA 以保证可复现性
