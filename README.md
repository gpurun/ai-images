# AI Images - GPU 容器镜像目录

面向客户的 GPU 加速 AI 推理容器镜像集合，包含基础运行时、推理引擎和开箱即用的模型产品。

## 📋 目录结构

```
├── bases/                  # 基础镜像层
│   ├── cuda-runtime/       # CUDA 12.8 + cuDNN 运行时
│   └── python-ml/          # Python 3.12 + PyTorch 2.6 cu128
│
├── engines/                # 推理引擎
│   ├── comfyui/            # ComfyUI >= 0.30.0 (图像/视频工作流)
│   └── llm/                # LLM 推理引擎
│       ├── vllm/           # vLLM 高性能推理
│       └── sglang/         # SGLang 结构化生成
│
├── products/               # 可部署产品镜像
│   └── video-minimax-h3-singularity/  # MiniMax H3 视频生成
│
├── contracts/              # 环境变量和接口规范
├── scripts/                # 构建和推送脚本
├── compose/                # Docker Compose 示例
├── .github/workflows/      # CI/CD 自动构建
├── versions.env            # 全局版本锁定
└── catalog.yaml            # 镜像目录清单
```

## 🛠️ 技术栈

### 固定版本
- **Python**: 3.12
- **CUDA**: 12.8.1 (cudnn-devel-ubuntu22.04)
- **PyTorch**: 2.6.0+cu128
- **ComfyUI**: v0.37.0 (原生 MiniMax-H3 节点支持)

### 推理引擎版本
- **vLLM**: 0.8.5
- **SGLang**: 0.4.6

## 🚀 快速开始

### 构建镜像

```bash
# 构建所有镜像
./scripts/build.sh

# 构建特定层级
./scripts/build.sh base        # 仅基础镜像
./scripts/build.sh engine      # 仅引擎镜像
./scripts/build.sh product     # 仅产品镜像

# 构建单个镜像
./scripts/build.sh bases/cuda-runtime
./scripts/build.sh products/video-minimax-h3-singularity
```

### 推送到 GitHub Container Registry

```bash
# 设置镜像仓库前缀
export IMAGE_REGISTRY=ghcr.io/gpurun

# 推送所有镜像
./scripts/push.sh

# 推送特定产品
./scripts/push.sh products/video-minimax-h3-singularity
```

## 📦 镜像命名规范

### GHCR 完整路径
- **基础镜像**: `ghcr.io/gpurun/base/{cuda-runtime,python-ml}:<tag>`
- **引擎镜像**: `ghcr.io/gpurun/engine/{comfyui,vllm,sglang}:<tag>`
- **产品镜像**: `ghcr.io/gpurun/product/<product-name>:<tag>`

### 本地开发标签
设置 `IMAGE_REGISTRY=` (空值) 使用本地短标签：
- `base/cuda-runtime:cu128`
- `engine/comfyui:v0.37.0`
- `product/video-minimax-h3-singularity:v1`

## 🎬 产品镜像：MiniMax H3 Singularity

第一个发布的产品镜像，基于 ComfyUI 的 MiniMax-H3 视频生成。

### 模型来源
- **Hugging Face**: [WarmBloodAban/Minimax-h3_Singularity](https://huggingface.co/WarmBloodAban/Minimax-h3_Singularity)
- **类型**: T2V/I2V/Ref2V/V2V 社区微调模型
- **引擎**: ComfyUI (原生 MiniMax H3 节点)

### 运行容器

```bash
docker run -d \
  --name minimax-h3 \
  --gpus all \
  -p 8188:8188 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -v $(pwd)/input:/input \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  -e HF_TOKEN=your_hf_token_here \
  ghcr.io/gpurun/product/video-minimax-h3-singularity:v1
```

### 环境变量
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `COMFYUI_PORT` | `8188` | ComfyUI Web UI 端口 |
| `WEIGHTS_ROOT` | `/models` | 模型权重挂载根目录 |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 启动时自动下载权重 (1=启用) |
| `HF_TOKEN` | - | Hugging Face 访问令牌 (可选) |
| `DIFFUSION_FILE` | `Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors` | 默认扩散模型 (11GB) |

### 卷挂载
- **`/models`**: 权重文件存储 (扩散模型、文本编码器、VAE)
- **`/output`**: 生成的视频输出
- **`/input`**: 输入图像/视频素材

### 权重下载策略

**镜像不预置多 GB 权重文件**，采用运行时按需下载或外部挂载：

1. **自动下载** (首次启动):
   ```bash
   -e AUTO_DOWNLOAD_WEIGHTS=1 -e HF_TOKEN=your_token
   ```

2. **手动挂载已有权重**:
   ```bash
   # 将本地权重目录映射到容器
   -v /path/to/your/models:/models
   ```

3. **容器内手动下载**:
   ```bash
   docker exec -it minimax-h3 download
   ```

### 需要的权重文件

自动下载脚本会拉取：

**主模型** (来自 `WarmBloodAban/Minimax-h3_Singularity`):
- `Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors` (~11.0 GB, 默认)

**依赖组件** (来自 `Comfy-Org/MiniMax-H3`):
- 文本编码器: `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors`
- 视频 VAE: `minimax_h3_video_vae_fp16.safetensors`
- 音频 VAE: `minimax_h3_audio_vae_fp32.safetensors`

### 访问 ComfyUI

容器启动后访问: `http://localhost:8188`

加载 MiniMax H3 工作流并开始生成视频！

## 🖼️ 产品系列：Qwen-Image-2.1 图像生成

阿里通义千问最新图像生成模型，提供 **6 个 SKU** 覆盖不同显存和运行时需求。

### 模型信息
- **Hugging Face**: [Qwen/Qwen-Image-2.1](https://huggingface.co/Qwen/Qwen-Image-2.1)
- **类型**: 文本生成图像 (T2I)、图像编辑
- **开发者**: 阿里云 / 通义千问团队

### 产品矩阵 (2 运行时 × 3 VRAM SKU)

#### Diffusers HTTP API 运行时 (端口 8000)

| SKU | 显存 | 精度 | 分辨率 | 镜像 |
|-----|------|------|--------|------|
| 4090-24g | 24GB | FP16 + CPU offload | 1024² | `image-qwen-image-21-diffusers-4090-24g:v1` |
| 48g | 48GB | BF16 full | 2048² | `image-qwen-image-21-diffusers-48g:v1` |
| 5090 | 32GB | BF16 | 1536² | `image-qwen-image-21-diffusers-5090:v1` |

**快速启动** (以 4090 24GB 为例):
```bash
docker run -d --gpus all -p 8000:8000 \
  -v $(pwd)/models:/models \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-4090-24g:v1

# API 调用
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "一只可爱的橘猫", "width": 1024, "height": 1024}'
```

#### ComfyUI 运行时 (端口 8188)

| SKU | 显存 | 精度 | 分辨率 | 镜像 |
|-----|------|------|--------|------|
| 4090-24g | 24GB | FP8/GGUF 量化 | 1024² | `image-qwen-image-21-comfyui-4090-24g:v1` |
| 48g | 48GB | BF16 full | 2048² | `image-qwen-image-21-comfyui-48g:v1` |
| 5090 | 32GB | BF16 | 1536² | `image-qwen-image-21-comfyui-5090:v1` |

**快速启动**:
```bash
docker run -d --gpus all -p 8188:8188 \
  -v $(pwd)/models:/models \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-comfyui-4090-24g:v1
```

访问 ComfyUI: **http://localhost:8188**

### 详细文档
完整的环境变量、API 文档、性能对比、故障排除等请查看：
- [Qwen-Image-2.1 完整文档](products/_qwen-image-21-shared/README.md)
- 各 SKU 产品目录: `products/image-qwen-image-21-*/README.md`

## 🔧 开发指南

### 修改版本锁定

编辑 `versions.env` 文件更改全局版本：

```bash
# 示例：升级 PyTorch
TORCH_VERSION=2.6.1

# 示例：切换 ComfyUI 版本
COMFYUI_REF=main
```

修改后重新构建受影响的镜像。

### 添加新产品

1. 在 `products/<product-name>/` 创建目录
2. 添加必需文件：
   - `Dockerfile` (FROM 适当的引擎镜像)
   - `entrypoint.sh` (启动脚本)
   - `download_weights.sh` (可选权重下载)
   - `README.md` (产品文档)
3. 在 `catalog.yaml` 注册产品
4. 在 `versions.env` 添加产品标签变量
5. 更新 `.github/workflows/build.yml` 路径过滤

### 环境规范

参见 `contracts/env.schema.md` 了解所有产品必须遵循的环境变量和接口约定。

## 🤖 CI/CD

GitHub Actions 自动构建和推送镜像到 GHCR：

- **触发条件**: Push 到 `main` 分支或手动 workflow_dispatch
- **路径过滤**: 仅在相关文件变更时构建对应镜像
- **权限**: 需要 `packages:write` (GHCR 推送)
- **秘密**: 自动使用 `GITHUB_TOKEN`

查看 `.github/workflows/build.yml` 了解完整配置。

## 📚 更多资源

- **模型源**: [Minimax-h3_Singularity on Hugging Face](https://huggingface.co/WarmBloodAban/Minimax-h3_Singularity)
- **ComfyUI 文档**: [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- **MiniMax H3 官方**: [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3)

## 📄 许可证

本仓库代码采用 Apache 2.0 许可证。各模型权重遵循其原始许可条款。

---

**维护者**: GPURun Team  
**更新日期**: 2026-09-22
