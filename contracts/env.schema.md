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

### LLM 健康检查
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<port>/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 120s
```

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
