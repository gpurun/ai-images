# 环境变量和接口规范

所有产品镜像必须遵循以下约定，确保一致的部署和运维体验。

## 📋 通用环境变量 (所有产品)

### 必需
无全局必需变量。各产品定义自己的必需参数。

### 可选
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LOG_LEVEL` | `INFO` | 日志级别 (DEBUG/INFO/WARNING/ERROR) |
| `HOST` | `0.0.0.0` | 服务监听地址 |

## 🎨 ComfyUI 产品规范

基于 `engine/comfyui` 的产品镜像必须实现：

### 端口
- **`8188`**: ComfyUI Web UI (固定)

### 卷挂载
| 路径 | 用途 | 必需 |
|------|------|------|
| `/models` | 模型权重存储 (扩散模型、VAE、LoRA 等) | 是 |
| `/output` | 生成内容输出目录 | 是 |
| `/input` | 输入素材 (图像/视频/音频) | 推荐 |

### 环境变量
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `COMFYUI_PORT` | `8188` | ComfyUI 服务端口 |
| `WEIGHTS_ROOT` | `/models` | 权重文件根目录 |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 启动时自动下载权重 (0/1) |
| `HF_TOKEN` | - | Hugging Face 访问令牌 (可选) |
| `HF_REPO` | - | 主模型仓库 (产品特定) |
| `DIFFUSION_FILE` | - | 默认扩散模型文件名 (产品特定) |

### 健康检查
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8188/system_stats"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Entrypoint 模式
所有 ComfyUI 产品的 `entrypoint.sh` 必须支持：

```bash
# 启动 ComfyUI 服务
docker run <image> serve    # 或 ui

# 手动下载权重
docker run <image> download

# 交互式 shell
docker run <image> bash

# 自定义命令
docker run <image> <custom_command> [args...]
```

### 模型目录结构
在 `/models` 下组织子目录：

```
/models/
├── diffusion_models/      # 扩散变换器检查点
├── text_encoders/         # 文本编码器 (CLIP, T5, Qwen 等)
├── vae/                   # VAE 模型
├── checkpoints/           # 完整检查点 (合并)
├── loras/                 # LoRA 适配器
├── controlnet/            # ControlNet 模型
├── embeddings/            # 文本嵌入/反转
└── upscale_models/        # 超分模型
```

产品的 `entrypoint.sh` 应将这些目录符号链接到 ComfyUI 内部路径。

## 🤖 LLM 产品规范 (vLLM / SGLang)

### vLLM
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VLLM_PORT` | `8000` | vLLM API 服务端口 |
| `MODEL_PATH` | `/models` | 模型权重路径 |
| `TENSOR_PARALLEL_SIZE` | `1` | 张量并行大小 |
| `GPU_MEMORY_UTILIZATION` | `0.9` | GPU 显存利用率 |
| `MAX_MODEL_LEN` | - | 最大上下文长度 (可选) |

**端口**: `8000` (OpenAI-compatible API)

### SGLang
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SGLANG_PORT` | `30000` | SGLang API 服务端口 |
| `MODEL_PATH` | `/models` | 模型权重路径 |
| `TP_SIZE` | `1` | 张量并行大小 |
| `MEM_FRACTION` | `0.9` | GPU 显存使用比例 |

**端口**: `30000` (OpenAI-compatible API)

### Ollama
基于 `engine/ollama` 的产品镜像必须实现：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OLLAMA_PORT` | `11434` | Ollama API 服务端口 |
| `OLLAMA_MODEL` | 产品特定 | 对外服务的模型名 (API 中的 model id) |
| `OLLAMA_PULL` | 产品特定 | 启动时拉取源 (registry tag 或 `hf.co/<repo>:<quant>`；与 `OLLAMA_MODEL` 不同则自动 `ollama create` 别名) |
| `GGUF_PATH` | - | 本地 GGUF 文件或目录 (优先级最高，任何模式下都会被 `ollama create`) |
| `OLLAMA_CONTEXT_LENGTH` | `131072` | 默认 128K 长上下文，可按模型能力上调 (最高 1048576) |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | KV cache 量化 (q8_0 ≈ f16 的 1/4 显存，长上下文必备) |
| `OLLAMA_FLASH_ATTENTION` | `1` | FlashAttention 加速 (0/1) |
| `OLLAMA_NUM_PARALLEL` | `4` | 并行请求数 |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | 常驻加载模型数 (性能默认，避免重复加载) |
| `OLLAMA_KEEP_ALIVE` | `-1` | 模型常驻不卸载 (秒数或 `-1`) |
| `OLLAMA_MODELS` | `/models/ollama` | 模型存储目录 (卷挂载) |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 是否允许联网拉取 (0/1)；`download` 模式强制执行 |

**端口**: `11434` (Ollama HTTP API，兼容 `/api/generate`、`/api/chat`；OpenAI 兼容端点 `/v1/*` 自 v0.5+ 可用)

**卷挂载**: `${MODELS_DIR:-./models}:/models` (模型与 gguf 缓存持久化)

**Entrypoint 模式**:
```bash
docker run <image>              # 默认 serve：后台起 ollama serve → 确保模型就绪 → 前台等待
docker run <image> serve        # 同上 (显式)
docker run <image> download     # 强制拉取/创建模型后退出 (init 容器预热，无需 AUTO_DOWNLOAD_WEIGHTS)
docker run <image> bash         # 交互式 shell
docker run <image> <cmd>        # 透传自定义命令
```

**性能/长上下文约定**: 引擎镜像必须以 `OLLAMA_FLASH_ATTENTION=1` + `OLLAMA_KV_CACHE_TYPE=q8_0` 构建默认值；产品 compose 必须持久化 `/models` 并设置 `OLLAMA_KEEP_ALIVE=-1`。

### JEV 决策模型 (vLLM, System 1 + System 2)

基于 `engines/llm/Dockerfile.vllm.jev-*` 的产品必须实现：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VLLM_PORT` | `8000` | vLLM API 服务端口（System 1/2 共用） |
| `MODEL_PATH` | `/models/<model>` | 模型本地目录（`serve_decide.py` 与 `adapter_vllm` 必须为本地文件） |
| `JEV_DECIDE_SCRIPT` | 自动探测 | `serve_decide.py` 显式路径；留空时按 `<MODEL>/serve_decide.py` → `<MODEL>/vl/serve_decide.py` 探测，未命中则回退普通 `vllm serve` |
| `TP_SIZE` | 1 / 2 / 4 | 张量并行（按产品：9B=1；27B 2 卡=2、4 卡=4） |
| `MAX_NUM_SEQS` | `8` | **硬约束**：批内 >8 序列时 System 1 概率错误，禁止改动 |
| `CONTEXT_LENGTH` | 产品定义 | `--max-model-len`（JEV-9B 8192 / JEV-27B-VL 32768，最高 262144） |
| `GPU_MEMORY_UTILIZATION` | `0.90` | GPU 显存利用率 |
| `MAX_LORA_RANK` | `32` | `--max-lora-rank`（决策 LoRA 上限） |
| `MAX_LOGPROBS` | `256` | `--max-logprobs`（客户端直接读选项 logprobs 的上限） |
| `MAX_IMAGES_PER_PROMPT` | `8` | `--limit-mm-per-prompt`（视觉产品） |
| `GPU_ID` / `GPU_ID_0..3` | `0`..`3` | `device_ids` 卡号选择（多卡产品必须可配） |

**端口**: `8000` (OpenAI-compatible API + `POST /v1/decide`)

**必备启动参数**: `--enable-lora --logprobs-mode processed_logprobs --enable-prefix-caching --mamba-cache-mode align --trust-request-chat-template --lora-modules jev-decision=<model>/adapter_vllm`，视觉产品另加 `--limit-mm-per-prompt`；`serve_decide.py` 需要 vLLM 开发版（`logprob_token_ids`）。

**Entrypoint**: 引擎镜像以 `jev-serve` 为 entrypoint，参数形式为 `<model-path> [vllm serve flags...]`（与 `vllm serve` / `serve_decide.py` 同一套 flag）。

### LLM 健康检查
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<port>/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 120s
```

> Ollama 基础镜像不含 `curl`，healthcheck 必须改用：
> ```yaml
> healthcheck:
>   test: ["CMD-SHELL", "ollama list >/dev/null 2>&1"]
>   interval: 30s
>   timeout: 10s
>   retries: 3
>   start_period: 180s
> ```

## 📦 权重管理策略

### ❌ 禁止行为
- **不得**将多 GB 权重文件 `COPY` 到镜像层
- **不得**在 `Dockerfile` 中 `RUN huggingface-cli download`

### ✅ 推荐方式
1. **外部挂载** (生产推荐):
   ```bash
   -v /data/models/minimax-h3:/models:ro
   ```

2. **运行时自动下载** (首次部署):
   ```bash
   -e AUTO_DOWNLOAD_WEIGHTS=1 -e HF_TOKEN=<token>
   ```

3. **预热 init 容器** (Kubernetes):
   ```yaml
   initContainers:
   - name: download-weights
     image: <product_image>
     command: ["download"]
     volumeMounts:
     - name: models
       mountPath: /models
   ```

### 下载脚本规范
每个产品的 `download_weights.sh` 必须：
- 检查文件是否已存在 (幂等性)
- 支持 `HF_TOKEN` 环境变量
- 优先使用 `hf` CLI，fallback 到 `huggingface-cli`
- 输出清晰的下载进度和最终路径

## 🔗 多阶段依赖

### 构建顺序
```
base/cuda-runtime  →  base/python-ml  →  engine/{comfyui,vllm,sglang}  →  product/*
base/ollama (独立) →  engine/ollama (FROM ollama/ollama，不依赖 python-ml)  →  product/*
```

### ARG 传递
各层 `Dockerfile` 通过 `ARG BASE_IMAGE` 引用父层：

```dockerfile
ARG BASE_IMAGE=base/python-ml:cu128-py312
FROM ${BASE_IMAGE}
```

构建脚本 (`scripts/build.sh`) 负责按依赖顺序传递正确的 `--build-arg BASE_IMAGE=...`。

## 🧪 测试验证

### 启动测试
```bash
docker run --rm --gpus all <image> bash -c "python --version && nvidia-smi"
```

### 服务健康测试
```bash
# ComfyUI
curl -f http://localhost:8188/system_stats

# vLLM / SGLang
curl -f http://localhost:<port>/health

# Ollama (基础镜像无 curl)
docker exec <container> ollama list
curl -f http://localhost:11434/api/version   # 宿主机侧
```

### 权重挂载测试
```bash
docker run --rm -v /tmp/empty-models:/models <image> ls -la /models
```

## 📝 文档要求

每个产品目录必须包含 `README.md`，内容涵盖：
- 模型来源和 Hugging Face 链接
- 快速启动命令 (docker run)
- 环境变量说明
- 卷挂载说明
- 资源需求 (GPU 显存、推荐硬件)
- 权重下载方式
- ComfyUI / API 访问地址

## 🚀 Compose 示例

`compose/` 目录提供各产品的 `docker-compose.yml` 参考，展示：
- 卷挂载配置
- GPU 设备分配
- 环境变量最佳实践
- 健康检查定义
- 多容器协作 (如 ComfyUI + LLM backend)

---

**合规检查**: 新产品 PR 必须通过 CI lint 验证以上规范。
