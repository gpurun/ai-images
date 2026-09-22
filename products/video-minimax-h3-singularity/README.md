# MiniMax H3 Singularity 视频生成

基于 ComfyUI 的 MiniMax-H3 社区微调模型，支持文本生成视频 (T2V)、图像生成视频 (I2V)、参考视频生成 (Ref2V) 和视频转视频 (V2V)。

## 🎯 模型信息

- **Hugging Face**: [WarmBloodAban/Minimax-h3_Singularity](https://huggingface.co/WarmBloodAban/Minimax-h3_Singularity)
- **类型**: MiniMax-H3 扩散变换器社区微调
- **引擎**: ComfyUI v0.37.0 (原生 MiniMax H3 节点)
- **任务**: T2V, I2V, Ref2V, V2V

## 🚀 快速启动

### 方式 1: Docker Run (自动下载权重)

```bash
docker run -d \
  --name minimax-h3 \
  --gpus all \
  -p 8188:8188 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -v $(pwd)/input:/input \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  -e HF_TOKEN=your_huggingface_token_here \
  ghcr.io/gpurun/product/video-minimax-h3-singularity:v1
```

**首次启动**: 自动下载约 11GB 扩散模型 + 依赖组件，需等待 10-30 分钟 (取决于网速)。

### 方式 2: Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  minimax-h3:
    image: ghcr.io/gpurun/product/video-minimax-h3-singularity:v1
    container_name: minimax-h3
    
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    
    ports:
      - "8188:8188"
    
    volumes:
      - ./models:/models
      - ./output:/output
      - ./input:/input
    
    environment:
      - AUTO_DOWNLOAD_WEIGHTS=1
      # - HF_TOKEN=your_token_here  # 可选
    
    restart: unless-stopped
```

启动:
```bash
docker-compose up -d
docker-compose logs -f  # 查看下载进度
```

### 方式 3: 预先挂载已有权重

如果你已有下载好的模型文件，跳过自动下载：

```bash
docker run -d \
  --name minimax-h3 \
  --gpus all \
  -p 8188:8188 \
  -v /path/to/your/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=0 \
  ghcr.io/gpurun/product/video-minimax-h3-singularity:v1
```

确保 `/models` 目录结构如下：

```
/models/
├── diffusion_models/
│   └── Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors  (11.0 GB)
├── text_encoders/
│   └── qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors
└── vae/
    ├── minimax_h3_video_vae_fp16.safetensors
    └── minimax_h3_audio_vae_fp32.safetensors
```

## 🌐 访问 ComfyUI

容器启动后访问: **http://localhost:8188**

加载 MiniMax H3 工作流节点并开始生成视频！

## 📋 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `COMFYUI_PORT` | `8188` | ComfyUI Web UI 端口 |
| `WEIGHTS_ROOT` | `/models` | 模型权重根目录 |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 启动时自动下载权重 (0=关闭, 1=启用) |
| `HF_TOKEN` | - | Hugging Face 访问令牌 (可选，用于私有/门禁模型) |
| `HF_REPO` | `WarmBloodAban/Minimax-h3_Singularity` | 主模型仓库 |
| `DIFFUSION_FILE` | `Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors` | 默认扩散模型文件 |
| `LOG_LEVEL` | `INFO` | 日志级别 (DEBUG/INFO/WARNING/ERROR) |

## 💾 卷挂载

| 容器路径 | 用途 | 推荐宿主机路径 |
|----------|------|----------------|
| `/models` | 模型权重存储 (持久化) | `./models` 或 `/data/models` |
| `/output` | 生成的视频输出 | `./output` |
| `/input` | 输入图像/视频素材 | `./input` |

## 🎨 模型权重详情

### 主模型 (WarmBloodAban/Minimax-h3_Singularity)

当前版本主要提供 **ref2va (Ref2V)** 检查点：

- ✅ **Minimax-h3_Singularity_ref2va_v1.3_Pruned_w4a8.safetensors** (~11.0 GB) — 默认使用
- `Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors` (~19.5 GB)
- `Minimax-h3_Singularity_ref2va_v1.3_int8.safetensors` (~31.7 GB)

### 依赖组件 (Comfy-Org/MiniMax-H3)

所有 MiniMax H3 工作流必需：

- **文本编码器**: `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors`
- **视频 VAE**: `minimax_h3_video_vae_fp16.safetensors`
- **音频 VAE**: `minimax_h3_audio_vae_fp32.safetensors`

### FL2VA (T2V/I2V) 支持

Singularity 仓库当前以 Ref2V 为主。如需 **T2V/I2V** (FL2VA) 能力，可额外下载官方 FL2VA 检查点：

- 来源: [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3)
- 示例: `minimax_h3_fl2va_pruned_int8_convrot.safetensors`
- 放置到: `models/diffusion_models/`

## 🖥️ 硬件需求

| 配置 | 最低 | 推荐 |
|------|------|------|
| **GPU 显存** | 24 GB | 40+ GB |
| **系统内存** | 32 GB | 64 GB |
| **GPU 型号** | RTX 4090 / A100-40GB | A100-80GB / H100 |
| **磁盘空间** | 50 GB | 100 GB (含多个检查点) |

## 🛠️ 手动操作

### 进入容器 Shell

```bash
docker exec -it minimax-h3 bash
```

### 手动下载权重

```bash
docker exec -it minimax-h3 download
```

或在容器内:
```bash
/usr/local/bin/download_weights.sh
```

### 查看日志

```bash
docker logs -f minimax-h3
```

## 🔍 健康检查

容器内置健康检查，自动探测 ComfyUI 服务状态：

```bash
curl -f http://localhost:8188/system_stats
```

## 🐛 故障排除

### 容器启动失败

```bash
# 查看详细日志
docker logs minimax-h3

# 检查 GPU 可用性
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

### 权重下载慢或失败

1. 检查网络连接到 Hugging Face
2. 使用镜像源 (国内):
   ```bash
   -e HF_ENDPOINT=https://hf-mirror.com
   ```
3. 预先用 `huggingface-cli` 手动下载再挂载

### ComfyUI 无法访问

- 检查端口映射: `docker ps | grep 8188`
- 防火墙规则
- 等待服务完全启动 (首次下载权重需要较长时间)

## 📦 构建自定义镜像

如需修改或扩展:

```bash
# 克隆仓库
git clone https://github.com/gpurun/ai-images.git
cd ai-images

# 构建镜像
./scripts/build.sh products/video-minimax-h3-singularity

# 本地标签
docker tag product/video-minimax-h3-singularity:v1 my-custom:latest
```

## 📖 相关链接

- **模型卡片**: https://huggingface.co/WarmBloodAban/Minimax-h3_Singularity
- **MiniMax H3 官方**: https://huggingface.co/Comfy-Org/MiniMax-H3
- **ComfyUI 项目**: https://github.com/comfyanonymous/ComfyUI
- **仓库主页**: https://github.com/gpurun/ai-images

## 📄 许可证

- 本镜像代码: Apache 2.0
- MiniMax-H3 模型: 遵循原始许可 (查看 Hugging Face 模型卡片)
- ComfyUI: GPL-3.0

---

**维护**: GPURun Team  
**更新**: 2026-09-22
