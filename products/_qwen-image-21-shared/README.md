# Qwen-Image-2.1 图像生成产品系列

阿里通义千问 Qwen-Image-2.1 的可部署容器镜像，支持文本生成图像 (T2I) 和图像编辑。

## 📦 产品矩阵

本系列提供 **6 个 SKU**：2 种运行时 × 3 种显存规格

### Diffusers HTTP API 运行时

基于 FastAPI 的 RESTful API 服务，端口 **8000**

| SKU | 显存需求 | 精度 | 默认分辨率 | 推荐 GPU |
|-----|----------|------|------------|----------|
| **diffusers-4090-24g** | 24 GB | FP16/FP8 + CPU offload | 1024×1024 | RTX 4090 |
| **diffusers-48g** | 48 GB | BF16 full | 2048×2048 | A100-80GB / H100 |
| **diffusers-5090** | 32 GB | BF16 | 1536×1536 | RTX 5090 |

### ComfyUI 运行时

图形化工作流编辑器，端口 **8188**

| SKU | 显存需求 | 精度 | 默认分辨率 | 推荐 GPU |
|-----|----------|------|------------|----------|
| **comfyui-4090-24g** | 24 GB | FP8/GGUF 量化 | 1024×1024 | RTX 4090 |
| **comfyui-48g** | 48 GB | BF16 full | 2048×2048 | A100-80GB / H100 |
| **comfyui-5090** | 32 GB | BF16 | 1536×1536 | RTX 5090 |

## 🎯 模型信息

- **Hugging Face**: [Qwen/Qwen-Image-2.1](https://huggingface.co/Qwen/Qwen-Image-2.1)
- **类型**: 扩散变换器 (Diffusion Transformer)
- **任务**: 文本生成图像 (T2I), 图像编辑
- **开发者**: 阿里云 / 通义千问团队

## 🚀 快速启动

### 方式 1: Diffusers API (HTTP)

#### 4090 24GB SKU (FP16 优化)
```bash
docker run -d \
  --name qwen-image-4090 \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-4090-24g:v1
```

**API 调用示例**:
```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "一只可爱的橘猫在草地上玩耍，高清摄影",
    "width": 1024,
    "height": 1024,
    "num_inference_steps": 28,
    "guidance_scale": 7.0
  }'
```

#### 48GB SKU (BF16 全精度 2K)
```bash
docker run -d \
  --name qwen-image-48g \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-48g:v1
```

#### RTX 5090 SKU (BF16 1.5K)
```bash
docker run -d \
  --name qwen-image-5090 \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-5090:v1
```

### 方式 2: ComfyUI (图形化界面)

#### 4090 24GB SKU
```bash
docker run -d \
  --name qwen-comfy-4090 \
  --gpus all \
  -p 8188:8188 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-comfyui-4090-24g:v1
```

访问 ComfyUI: **http://localhost:8188**

#### 48GB / 5090 SKU
将镜像名替换为对应 SKU 即可：
- `image-qwen-image-21-comfyui-48g:v1`
- `image-qwen-image-21-comfyui-5090:v1`

## 📋 环境变量

### Diffusers API 运行时

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VARIANT` | `4090-24g` / `48g` / `5090` | 自动设置，无需手动修改 |
| `PORT` | `8000` | HTTP API 端口 |
| `MODEL_PATH` | `/models` | 模型权重路径 |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 启动时自动下载权重 (1=启用) |
| `HF_TOKEN` | - | Hugging Face 访问令牌 (可选) |
| `TORCH_DTYPE` | 自动 | `fp16` / `bf16` / `auto` |
| `ENABLE_CPU_OFFLOAD` | 根据 SKU | 24g=1, 其他=0 |
| `DEFAULT_WIDTH` | 根据 SKU | 默认图像宽度 |
| `DEFAULT_HEIGHT` | 根据 SKU | 默认图像高度 |

### ComfyUI 运行时

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VARIANT` | `4090-24g` / `48g` / `5090` | 自动设置 |
| `COMFYUI_PORT` | `8188` | ComfyUI Web UI 端口 |
| `MODEL_PATH` | `/models` | 模型权重路径 |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 启动时自动下载 |
| `QUANT_MODE` | `fp8` / `bf16` | 量化模式 |

## 💾 卷挂载

| 容器路径 | 用途 | 必需 |
|----------|------|------|
| `/models` | 模型权重存储 (持久化) | **是** |
| `/output` | 生成图像输出 | 推荐 |
| `/input` | 输入图像 (用于编辑任务) | 可选 |

## 🎨 权重管理

### ❌ 镜像层不包含权重
按照最佳实践，**所有产品镜像均不预装模型权重**。

### ✅ 权重获取方式

1. **自动下载** (首次启动):
   ```bash
   -e AUTO_DOWNLOAD_WEIGHTS=1 -e HF_TOKEN=your_token
   ```
   下载时间约 10-30 分钟（取决于网速），模型约 15-20 GB。

2. **手动挂载已有权重**:
   ```bash
   -v /data/models/qwen-image-21:/models
   ```

3. **容器内手动下载**:
   ```bash
   docker exec -it qwen-image-4090 download
   ```

### 权重目录结构
```
/models/
├── model_index.json
├── scheduler/
├── text_encoder/
├── tokenizer/
├── transformer/
├── vae/
└── ...
```

## 🔧 SKU 详细说明

### 4090-24g: RTX 4090 优化 (24GB)
- **精度**: FP16 / FP8 量化
- **特性**: 启用 CPU offload 减少显存占用
- **默认分辨率**: 1024×1024 (可调整到 1536)
- **推理速度**: ~3-5秒/张 (28步)
- **适用场景**: 高性价比个人/小团队部署

### 48g: 高端 GPU (48GB+)
- **精度**: 全 BF16
- **默认分辨率**: 2048×2048 原生支持
- **推理速度**: ~2-4秒/张 (28步)
- **适用场景**: 生产环境高质量输出
- **推荐硬件**: A100-80GB, H100-80GB

### 5090: RTX 5090 专属 (32GB)
- **精度**: BF16
- **默认分辨率**: 1536×1536
- **推理速度**: ~2.5-4秒/张 (28步)
- **适用场景**: 新一代消费级旗舰 GPU 部署
- **注**: RTX 5090 规格按预期 ~32GB VRAM 设定

## 🌐 API 文档 (Diffusers 运行时)

### 健康检查
```bash
GET /health

Response:
{
  "status": "healthy",
  "model": "Qwen/Qwen-Image-2.1"
}
```

### 生成图像
```bash
POST /generate

Request Body:
{
  "prompt": "文本提示词",
  "negative_prompt": "负面提示词 (可选)",
  "width": 1024,
  "height": 1024,
  "num_inference_steps": 28,
  "guidance_scale": 7.0,
  "seed": 42 (可选，固定随机种子)
}

Response:
{
  "image": "base64_encoded_png",
  "format": "png",
  "width": 1024,
  "height": 1024
}
```

### Python 客户端示例
```python
import requests
import base64
from PIL import Image
from io import BytesIO

url = "http://localhost:8000/generate"
payload = {
    "prompt": "一只可爱的橘猫在草地上玩耍，高清摄影",
    "width": 1024,
    "height": 1024,
    "num_inference_steps": 28,
    "guidance_scale": 7.0
}

response = requests.post(url, json=payload)
result = response.json()

# 解码 base64 图像
img_data = base64.b64decode(result["image"])
img = Image.open(BytesIO(img_data))
img.save("output.png")
```

## 🧩 ComfyUI 工作流

### 自定义节点要求
- **ComfyUI-GGUF**: 24GB SKU 使用 GGUF 量化模型（已预装）
- **Qwen-Image-2.1 节点**: 官方或社区节点（检查 ComfyUI 生态更新）

### 工作流提示
1. 将 Qwen-Image-2.1 检查点放入 `/models/checkpoints/` 或 `/models/diffusion_models/`
2. 使用标准 T2I 节点连接 Qwen 模型
3. 24GB SKU 使用 GGUF 量化版本以节省显存

## 📊 性能对比

| SKU | 显存占用 | 1024² 速度 | 2048² 速度 | 最大分辨率 |
|-----|----------|------------|------------|-----------|
| 4090-24g | ~20 GB | 3-5s | N/A | 1536×1536 |
| 48g | ~35 GB | 2-3s | 2-4s | 2560×2560+ |
| 5090 | ~28 GB | 2.5-4s | ~5-7s | 2048×2048 |

*速度基于 28 推理步数估算，实际性能依硬件和 CUDA 版本变化。

## 🐛 故障排除

### 容器启动失败
```bash
# 查看日志
docker logs qwen-image-4090

# 检查 GPU 可用性
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

### 显存不足 (OOM)
- **4090-24g SKU**: 确保没有其他程序占用 GPU，或降低分辨率到 768×768
- **48g/5090 SKU**: 检查是否误用了更高分辨率（如 4096×4096）

### 权重下载慢或失败
- 使用 HF 国内镜像: `-e HF_ENDPOINT=https://hf-mirror.com`
- 预先用 `huggingface-cli` 下载后挂载

### API 无响应
- 等待模型加载完成（首次启动需 1-2 分钟）
- 检查端口映射: `docker ps | grep 8000`

## 🔗 相关链接

- **模型主页**: https://huggingface.co/Qwen/Qwen-Image-2.1
- **Diffusers 文档**: https://huggingface.co/docs/diffusers
- **ComfyUI 项目**: https://github.com/comfyanonymous/ComfyUI
- **仓库主页**: https://github.com/gpurun/ai-images

## 📝 注意事项

1. **模型版本**: 基于 Qwen-Image-2.1 (截至 2024 年 12 月)，未来更新可能调整 API
2. **量化方案**: 24GB SKU 的 FP8/GGUF 量化可能需要额外转换（检查 HF 仓库官方量化版本）
3. **ComfyUI 支持**: Qwen-Image-2.1 ComfyUI 原生支持取决于社区节点进度
4. **RTX 5090**: 规格基于预测，实际硬件发布后可能需调整

## 📄 许可证

- **镜像代码**: Apache 2.0
- **Qwen-Image-2.1 模型**: 遵循通义千问模型许可（查看 Hugging Face 模型卡片）

---

**维护**: GPURun Team  
**更新**: 2026-09-22
