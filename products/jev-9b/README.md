# JEV-9B（单卡 RTX 4090 决策模型）

模型地址：[https://huggingface.co/autotrust/JEV-9B](https://huggingface.co/autotrust/JEV-9B)

`autotrust/JEV-9B` 是 AutoTrust 首个一体化 **System 1 + System 2** 开放模型：同一套权重、同一个 vLLM 引擎，按请求路由。*System 1* 单次前向给出类型化决策的校准概率（`noul` 是/否 · `choice` 2–16 选项 · `score` 0–5 分），*System 2* 是未经改动的 Qwen3.5-9B 文本生成与思考。基于 Blocks of Experts 配方：冻结的 Qwen3.5-9B 底座 + 40.2M System 1 LoRA + 24 槽决策头；2026-10-03 起 `vl/` 提供视觉能力（相机图像 / 截图 → 单次前向决策概率）。

本产品按当前项目标准提供 **vLLM** 引擎容器化部署（JEV 的 System 1 依赖 vLLM 的 LoRA / `processed_logprobs` 路径，SGLang 与 Ollama 不支持 `POST /v1/decide`，故不提供），针对 **单卡 RTX 4090 24GB** 调优，并含文本模式与视觉模式两套 Compose。

## 1. 模型信息

| 字段 | 值 |
|---|---|
| Model ID | `autotrust/JEV-9B` |
| Served Name | `autotrust/JEV-9B`（可在 `.env` 中修改） |
| 架构 | Qwen3.5-9B 底座（`qwen3_5`）+ System 1 LoRA（r=16, 40.2M）+ 24 槽 fp32 决策头 |
| 参数规模 | 7.9B（文本权重，`adapter_vllm/` 另含 176MB adapter）；视觉模式底座 `Qwen/Qwen3.5-9B` 9.65B |
| 精度 | BF16 |
| 权重体积 | 文本约 18 GB；视觉底座约 19.3 GB |
| 上下文长度 | 按显存调优：文本默认 8192（上游文本 serve 建议 4096 起），视觉默认 32768（`CONTEXT_LENGTH` / `VISION_CONTEXT_LENGTH`） |
| 输出能力 | System 1 `POST /v1/decide`（校准概率）+ System 2 OpenAI 兼容 `/v1/chat/completions` |
| License | Apache-2.0 |

## 2. GPU 卡型、数量及硬件要求

### 推荐配置

| GPU 型号 | 显存（单卡） | 推荐数量 | 并行方式 | 权重占用 | 说明 |
|---|---|---|---|---|---|
| **NVIDIA RTX 4090** | 24GB | **1 卡** | TP=1 | 文本 18GB / 视觉 19.3GB | **目标部署**；`GPU_MEMORY_UTILIZATION=0.90` 下文本余量充足，视觉模式建议按需下调上下文 |
| NVIDIA RTX 5090 | 32GB | 1 卡 | TP=1 | 同上 | 余量更大，上下文与图片数可上调 |
| NVIDIA A100/H100/H200 80GB | 80GB | 1 卡 | TP=1 | 同上 | 生产环境，长上下文 + 高并发 |
| 多卡场景 | >= 16GB | 2–4 卡 | TP=2/4 | 按卡均分 | 单卡模型非必需；JEV-9B 定位低延迟单卡 |

> `--max-num-seqs 8` 是 JEV 的硬约束（见第 7 节），并发超出部分仅排队，不影响结果正确性。

### 系统硬件要求

| 项目 | 要求 | 说明 |
|---|---|---|
| CPU | 8 核以上（推荐 16 核） | 模型加载与请求处理 |
| 内存（RAM） | >= 32 GB（推荐 48 GB） | 权重加载与共享内存 |
| 系统盘 | >= 40 GB（可用） | 镜像与日志 |
| 数据盘（模型缓存） | >= 45 GB（可用） | 文本约 18 GB + 视觉底座约 19.3 GB + 缓存余量 |
| 共享内存（SHM） | >= 32 GB（Compose 默认 64g） | `shm_size` |
| PCIe | PCIe 4.0+ | 单卡无跨卡通信要求 |

## 3. 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | 通用 |
| NVIDIA 驱动 | >= 535.129.03（推荐 >= 550.xx） | 支持 CUDA 12.8 |
| CUDA | 12.8.x | 基于 `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04` 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |
| 网络 | 稳定 | 首次下载模型约 18–40 GB |

## 4. 快速开始

构建镜像（vLLM 引擎 + 产品镜像两步，vLLM 取 `main` 开发版以支持 `qwen3_5` / `--logprobs-mode`）：

```bash
ENGINE=vllm ./scripts/build.jev-9b.sh
```

进入产品目录并准备配置：

```bash
cd products/jev-9b
cp .env.example .env
# 按需调整 GPU_ID（默认 0）、CONTEXT_LENGTH 等
```

下载权重（**必须下载到本地目录**，`serve_decide.py` 与 `adapter_vllm` 需为本地文件；`.env` 的 `MODELS_DIR` 会被挂载到容器 `/models`）：

```bash
# 文本模式（System 1 + System 2，约 18 GB，已含 vl/ 视觉 adapter 与 serve_decide.py）
huggingface-cli download autotrust/JEV-9B --local-dir ./models/JEV-9B

# 视觉模式额外需要 Qwen3.5-9B 视觉底座（约 19.3 GB，固定 revision）
huggingface-cli download Qwen/Qwen3.5-9B \
  --revision c202236235762e1c871ad0ccb60c8ee5ba337b9a \
  --local-dir ./models/Qwen3.5-9B
```

## 5. 启动

### 文本模式：System 1 + System 2（Docker Compose，默认）

```bash
docker compose -f docker-compose.vllm.yaml up -d --build
```

`MODEL_PATH=/models/JEV-9B` 时 entrypoint 自动探测 `serve_decide.py`（含 `vl/serve_decide.py`），服务器自带 `POST /v1/decide`；若仅用 HF 缓存中的 repo id（未落本地目录），会回退为普通 `vllm serve`，System 1 仍可走客户端 logprobs 路径（见第 7 节）。

### 视觉模式：图像输入的 System 1 / System 2（Docker Compose）

```bash
docker compose -f docker-compose.vllm-vl.yaml up -d --build
```

视觉模式服务 `Qwen/Qwen3.5-9B` 底座 + `JEV-9B/vl/adapter_vllm` 决策 LoRA，对外 model 名仍为 `autotrust/JEV-9B`，`JEV_DECIDE_SCRIPT` 已默认指向 `vl/serve_decide.py`。

## 6. 验证

```bash
# 模型与端点（端口 8000）
curl http://127.0.0.1:8000/v1/models

# System 1：类型化决策（校准概率）
curl -X POST http://127.0.0.1:8000/v1/decide -H 'Content-Type: application/json' -d '{
  "kind": "choice",
  "state": "SKU AX-330 stock at 8% of safety level; supplier late twice this quarter.",
  "question": "Supplier response for this scenario.",
  "options": ["issue_warning", "renegotiate", "dual_source", "maintain"]}'

# System 1：是/否
curl -X POST http://127.0.0.1:8000/v1/decide -H 'Content-Type: application/json' -d '{
  "kind": "noul",
  "state": "Customer says the parcel arrived damaged and wants their money back.",
  "question": "Is the customer asking for a refund?"}'

# System 2：普通生成（同一引擎）
curl -X POST http://127.0.0.1:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "autotrust/JEV-9B",
  "messages": [{"role": "user", "content": "In one sentence, what is safety stock?"}],
  "max_tokens": 60, "chat_template_kwargs": {"enable_thinking": false}}'

# 可选：决策头能力与温度
curl http://127.0.0.1:8000/v1/decide/info
```

视觉模式下的 System 1（`state` 中混入图片，data URL 或 `https://` 均可）：

```bash
curl -X POST http://127.0.0.1:8000/v1/decide -H 'Content-Type: application/json' -d '{
  "kind": "choice",
  "state": ["Top camera image:", {"image": "https://example.com/scene.png"},
            "\nTask: put the red cube in the tray."],
  "question": "Is the red cube to the left or to the right of the gripper?",
  "options": ["left", "right"]}'
```

## 7. 注意事项

- **`--max-num-seqs 8` 保持不变（视觉模式硬约束）**：批内超过 8 个序列时，vLLM 的 LoRA 路径对多模态模型类返回错误的 System 1 概率（上游 `vl/serve.sh` 明确要求）；限 8 后任意客户端并发下结果均正确，超出请求仅排队。本产品文本模式同样默认限 8，使两种模式行为一致。
- **`--logprobs-mode processed_logprobs` 必须开启**：它使返回的 log-probabilities 遵守 `allowed_token_ids`，是决策概率读取的前提。
- **启用 `POST /v1/decide` 的前提**：模型以本地目录方式挂载（`MODEL_PATH=/models/JEV-9B`）。`serve_decide.py` 需要 vLLM 开发版（2026-09 测试，使用 `logprob_token_ids`）；引擎镜像已按 `vllm@main` 构建。启动含 LoRA 的 CUDA graph 捕获，**首次就绪约 3–8 分钟**。
- **绕过 `serve_decide.py` 的客户端调用**：按模型卡示例用 `/v1/completions`、`model: "jev-decision"`、`max_tokens: 1`、`temperature: 1.0` 与 `allowed_token_ids` 读取选项 token，再叠加 `adapter_vllm/decision_head.json` 的 bias 与 `calibration.json` 的温度做 softmax（模型卡第 3 节有完整示例）；优先使用 `POST /v1/decide`。
- **4090 显存调优**：文本 18GB / 视觉 19.3GB 权重 + `GPU_MEMORY_UTILIZATION=0.90`，默认上下文分别为 8192 / 32768；OOM 时下调 `CONTEXT_LENGTH`（或 `VISION_CONTEXT_LENGTH`），或将利用率上调至 0.95（不建议更高）。
- **文本模式与视觉模式**：文本模式权重更小、上下文余量更大；视觉模式决策为 zero-shot（图像决策的校准未系统测量），大图建议先降采样（如最长边 448px）以减少视觉 token 与延迟。
- **选项顺序敏感性**：16 选项约 7% 的答案会随选项顺序改变；成对评判建议两个顺序各问一次并取平均。
- **数值精度**：bf16 批处理下概率第三位小数级波动属正常；批量吞吐场景（128/批）单决策约 2.5ms（B200 实测，仅供参考）。
- **并发与吞吐**：System 1 单请求中位约 90ms、约 340 决策/秒（B200）；同一 state 的多问题配合 `--enable-prefix-caching` 可再提升 14–20%。
