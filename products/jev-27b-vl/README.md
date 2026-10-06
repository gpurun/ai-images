# JEV-27B-VL（2 卡 / 4 卡部署）

模型地址：[https://huggingface.co/autotrust/JEV-27B-VL](https://huggingface.co/autotrust/JEV-27B-VL)

`autotrust/JEV-27B-VL` 是 `autotrust/JEV-27B` 的视觉版本：底座为未改动的 **Qwen/Qwen3.8-27B**，叠加 JEV System 1 adapter 与决策头。同一 vLLM 引擎同时提供 *System 1*（`POST /v1/decide`：文本与图像的类型化决策，单次前向输出每个选项的校准概率，`choice` 支持 **2–256 个选项**、提示词最长 **256K tokens**）与 *System 2*（未改动的 Qwen3.8-27B，可开关逐步思考，支持图像输入）。

本产品按当前项目标准提供 **vLLM** 引擎容器化部署与 **2 卡（TP=2）/ 4 卡（TP=4）** 两种部署方式（JEV 的 System 1 依赖 vLLM 的 LoRA / `processed_logprobs` 路径，SGLang 与 Ollama 不支持 `POST /v1/decide`，故不提供）。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `autotrust/JEV-27B-VL` |
| Served Name | `autotrust/JEV-27B-VL`（可在 `.env` 中修改） |
| 架构 | Qwen3.8-27B 底座 + System 1 LoRA（108.9M）+ 决策头（`adapter_vllm/`） |
| 参数规模 | 28B（BF16） |
| 精度 | BF16（原生权重，未量化） |
| 权重体积 | 约 52 GB（18 个 safetensors 分片） |
| 上下文长度 | 262144（256K，原生）；默认部署 32768，按显存上调 |
| 输出能力 | System 1 `POST /v1/decide`（noul / choice 2–256 / score，文本+图像）+ System 2 OpenAI 兼容 API |
| License | Apache-2.0 |

## 2. GPU 卡型、数量及硬件要求

BF16 权重约 52 GB，按 TP 均分后还需预留激活与 KV Cache（约 **65 KB/token**，满 256K 上下文约需 **17 GB** KV）。

### 推荐配置

| 部署方式 | GPU 型号 | 显存（单卡） | 数量 | 并行方式 | 单卡权重 | 说明 |
|---|---|---|---|---|---|---|
| **2 卡** | L40S / A6000 / RTX PRO 6000 | 48GB | **2 卡** | TP=2 | 27.8 GB | **推荐 2 卡形态**；可跑 128K–256K 上下文 |
| **2 卡** | A100 / H100 / H200 / B200 | 80GB+ | **2 卡** | TP=2 | 27.8 GB | 生产环境，满 256K 上下文 + 高并发 |
| **2 卡（不可行）** | RTX 4090 24GB ×2 | 24GB | 2 卡 | TP=2 | 27.8 GB | ❌ 单卡权重已超 24GB，无法加载 |
| **4 卡** | **RTX 4090 24GB ×4** | 24GB | **4 卡** | TP=4 | 13.9 GB | **性价比方案**：默认 32K 上下文，`utilization=0.90` 下 KV 余量约 30 GB，可上调至 256K |
| **4 卡** | A100 / H100 80GB ×4 | 80GB | 4 卡 | TP=4 | 13.9 GB | 满 256K 上下文 + 最高并发 |

> 判定原则：`单卡显存 × 0.90 > 52GB / 卡数 + 所需 KV`。2 卡请优先选择单卡 >= 48GB 的型号；4 卡 24GB 即可运行。

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 16 核以上（推荐 24–32 核） | 权重加载与长上下文处理 |
| 内存（RAM） | >= 64 GB（推荐 96–128 GB） | 模型加载与请求处理 |
| 系统盘 | >= 60 GB（可用） | 镜像与日志 |
| 数据盘（模型缓存） | >= 70 GB（可用） | 权重约 52 GB + 缓存余量 |
| 共享内存（SHM） | >= 64 GB | Compose 中 `shm_size` |
| PCIe/NVLink | PCIe 4.0+；2 卡/4 卡 TP 走 PCIe 时带宽影响延迟 | NVLink 更佳（支持的机型） |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 通用 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 |
| CUDA | 12.8.x | 基于 `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04` 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定 | 首次下载权重约 52 GB |

## 4. 快速开始

构建镜像（vLLM 引擎 + 产品镜像两步，vLLM 取 `main` 开发版以支持 Qwen3.8 架构、`--logprobs-mode` 与 `logprob_token_ids`）：

```bash
ENGINE=vllm ./scripts/build.jev-27b-vl.sh
```

进入产品目录并准备配置：

```bash
cd products/jev-27b-vl
cp .env.example .env
# 2 卡默认使用 GPU 0,1；4 卡默认使用 GPU 0,1,2,3，可在 .env 中用 GPU_ID_0..3 指定卡号
```

下载权重（**必须下载到本地目录**，`serve_decide.py` 与 `adapter_vllm` 需为本地文件；`.env` 的 `MODELS_DIR` 会被挂载到容器 `/models`）：

```bash
huggingface-cli download autotrust/JEV-27B-VL --local-dir ./models/JEV-27B-VL   # 约 52 GB
```

## 5. 启动

### 2 卡部署（TP=2，单卡 >= 48GB）

```bash
docker compose -f docker-compose.vllm-2gpu.yaml up -d --build
```

### 4 卡部署（TP=4，单卡 >= 24GB，如 4×RTX 4090）

```bash
docker compose -f docker-compose.vllm-4gpu.yaml up -d --build
```

两个 Compose 的差异仅并行度与卡号选择：

| 项 | 2 卡 | 4 卡 |
|---|---|---|
| `--tensor-parallel-size` | `${TP_SIZE:-2}` | `${TP_SIZE:-4}` |
| `device_ids` | `GPU_ID_0, GPU_ID_1` | `GPU_ID_0..GPU_ID_3` |
| 默认上下文 | 32768（可上调 262144） | 32768（可上调 262144） |

> `.env` 中若显式设置了 `TP_SIZE`，会同时覆盖两个 Compose 的默认值；不设置时各自取 2 / 4。256K 上下文请设 `CONTEXT_LENGTH=262144`（需约 17 GB KV，按第 2 节公式核算卡型）。

## 6. 验证

```bash
# 模型与端点（端口 8000）
curl http://127.0.0.1:8000/v1/models

# System 1：多选决策（2–256 个选项，返回每个选项的校准概率）
curl -X POST http://127.0.0.1:8000/v1/decide -H 'Content-Type: application/json' -d '{
  "kind": "choice",
  "state": "Customer: my card was charged twice for one coffee.",
  "question": "Which team should handle this?",
  "options": ["billing", "shipping", "tech support"]}'

# System 1：图像决策（state 为列表，图片可用 data URL 或 https URL）
curl -X POST http://127.0.0.1:8000/v1/decide -H 'Content-Type: application/json' -d '{
  "kind": "choice",
  "state": ["Listing photo: ", {"image": "https://example.com/item.jpg"},
            "\nSeller title: wireless earbuds, barely used"],
  "question": "Which category fits this listing?",
  "options": ["electronics", "clothing", "home and kitchen", "toys"]}'

# System 2：图像理解（同一引擎）
curl -X POST http://127.0.0.1:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "autotrust/JEV-27B-VL",
  "messages": [{"role": "user", "content": [
    {"type": "image_url", "image_url": {"url": "https://example.com/chart.png"}},
    {"type": "text", "text": "What does this chart show?"}]}],
  "max_tokens": 1024, "chat_template_kwargs": {"enable_thinking": false}}'

# 可选：决策头上限与温度
curl http://127.0.0.1:8000/v1/decide/info
```

## 7. 关键说明

- **`--max-num-seqs 8` 必须保持**：批内超过 8 个序列时，vLLM 的 LoRA 路径对该多模态模型类返回错误的 System 1 概率；限 8 之后任意客户端并发下结果均正确，超出请求仅排队（实测限 8 吞吐不受明显影响）。
- **`--trust-request-chat-template` 已启用**：`/v1/decide` 与客户端代码需要它来渲染图像决策的原始决策模板；System 2 使用模型自带 chat template。
- **`--logprobs-mode processed_logprobs` 必须开启**；`serve_decide.py` 内部使用 `logprob_token_ids`（每次至多 128 个），因此**必须使用 vLLM 开发版**（2026-09 测试），引擎镜像已按 `vllm@main` 构建。启动含 LoRA 的 CUDA graph 捕获，**首次就绪约 3–8 分钟**。
- **上下文与显存**：KV 约 65 KB/token。默认 `CONTEXT_LENGTH=32768`（约 2 GB KV）；`262144` 满上下文约需 17 GB KV。4×4090（utilization 0.90）权重后剩余约 30 GB，可容纳 256K；2×48GB 亦可（剩余约 30 GB）；2×40GB A100 建议 <=131072。
- **256 选项与策略**：`choice` 超过 16 个选项时使用决策头未训练过的字母标签（A–P 后接 Q–Z、AA…），响应的 `adaptation` 字段标明 `native`（<=16）或 `wide-labels`；可通过请求字段 `strategy` 指定 `single` / `tournament` / `permute`（顺序敏感场景建议 `permute` 或两种顺序各问一次取平均）。
- **思考与自适应**：请求可带 `thinking: "off"|"auto"|"on"` 与 `threshold`——`auto` 在 System 1 领先选项概率低于阈值时唤起 System 2 思考并加权融合；`chat_template_kwargs` / `reasoning_effort` 控制 Qwen3.8 思考强度。
- **绕过 `serve_decide.py` 的客户端调用**：需传 `top_k: 0`、`top_p: 1.0`（模型 `generation_config` 默认 `top_k=20`、`top_p=0.95` 会截断概率），并自行叠加 `adapter_vllm/decision_head.json` bias 与 `calibration.json` 温度做 softmax；compose 已设 `--max-logprobs 256` 以支持客户端直接读取至多 256 个选项的 logprobs。优先使用 `POST /v1/decide`。
- **图像预处理**：大图先降采样（如最长边 448px）可显著减少视觉 token 与延迟；`--limit-mm-per-prompt` 默认每请求 8 张图（`MAX_IMAGES_PER_PROMPT`）。
- **概率数值**：bf16 下第三位小数级波动属正常（取决于批内请求）。
