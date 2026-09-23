# VDN-MiniMax-H3 视频生成

OpenVDN VDN-H3 (Video DeltaNet on MiniMax-H3) 混合注意力视频生成模型，支持双模式推理：SGLang Diffusion（多 GPU 最优）和 Diffusers HTTP API（单 GPU 24GB 友好）。

## 🎯 模型信息

- **Hugging Face**: [OpenVDN/vdn-minimax-h3](https://huggingface.co/OpenVDN/vdn-minimax-h3)
- **代码仓库**: [github.com/OpenVDN/vdn-minimax-h3](https://github.com/OpenVDN/vdn-minimax-h3)
- **类型**: MiniMax-H3 混合注意力派生模型（线性注意力分支 + LoRA 适配器）
- **任务**: T2VA（文本生成视频）, I2VA（图像生成视频）, FL2VA（首尾关键帧）, L2VA（末尾关键帧）, Ref2VA-like（参考图像）
- **许可证**: MiniMax H3 社区许可协议（派生模型）

## ⚡ 性能亮点

- **8×B200 GPU (SGLang Diffusion)**: 生成 14.4 秒视频仅需 **6.9 秒去噪** + 约 9 秒端到端
- **单 H200 GPU (FP8)**: 8 步去噪 90.5 秒
- **单 RTX 5090 (24GB Diffusers + offload)**: 支持 345 帧（峰值 ~22GB 显存）

## 🚀 快速启动

### 模式 1: SGLang Diffusion（推荐，多 GPU 最快）

适用于生产环境、多 GPU 部署，最佳性能。

```bash
docker run -d \
  --name vdn-h3-sglang \
  --gpus all \
  -p 30010:30010 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e SERVE_MODE=sglang \
  -e NUM_GPUS=8 \
  -e QUANTIZATION=fp8 \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  -e HF_TOKEN=your_hf_token \
  ghcr.io/gpurun/product/video-vdn-minimax-h3:v1
```

**多 GPU 配置示例**:
- `NUM_GPUS=1`: 单卡（B200: 51s/8 步, H200: 90.5s/8 步）
- `NUM_GPUS=2`: 双卡（B200: 25.9s/8 步）
- `NUM_GPUS=4`: 四卡（B200: 13.1s/8 步）
- `NUM_GPUS=8`: 八卡（B200: 6.9s/8 步，**最快**）

**测试 API**:
```bash
# 健康检查
curl http://localhost:30010/health

# 生成视频（SGLang API 格式）
curl -X POST http://localhost:30010/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "一只可爱的橘猫在阳光下玩耍",
    "num_frames": 345,
    "num_inference_steps": 8
  }'
```

### 模式 2: Diffusers HTTP API（单 GPU 24GB 友好）

适用于 RTX 4090 / 5090 / A6000 等单卡场景，自动 offload 优化。

```bash
docker run -d \
  --name vdn-h3-diffusers \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e SERVE_MODE=diffusers \
  -e OFFLOAD_DIT=1 \
  -e QUANTIZATION=fp8 \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/video-vdn-minimax-h3:v1
```

**测试 API**:
```bash
# 健康检查
curl http://localhost:8000/health

# 生成视频
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "一片宁静的森林，晨雾缭绕，阳光透过树叶洒下",
    "num_frames": 345,
    "num_inference_steps": 9,
    "seed": 42
  }'

# 下载生成的视频
curl http://localhost:8000/download/video_20261123_143022.mp4 -O
```

### 模式 3: Docker Compose（生产部署）

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  vdn-h3:
    image: ghcr.io/gpurun/product/video-vdn-minimax-h3:v1
    container_name: vdn-h3
    
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all  # 或指定 count: 8
              capabilities: [gpu]
    
    ports:
      - "30010:30010"  # SGLang
      - "8000:8000"    # Diffusers (备用)
    
    volumes:
      - ./models:/models
      - ./output:/output
      - ./input:/input
    
    environment:
      # === 服务模式 ===
      - SERVE_MODE=sglang         # sglang 或 diffusers
      
      # === SGLang 配置 (SERVE_MODE=sglang) ===
      - NUM_GPUS=8                # GPU 数量 (1/2/4/8)
      - QUANTIZATION=fp8          # fp8 或 bf16
      - ATTENTION_BACKEND=hybrid_window_attn_h3
      - PERFORMANCE_MODE=speed
      - WARMUP_FRAMES=345
      - WARMUP_RESOLUTION=1344x768
      - SGLANG_PORT=30010
      
      # === Diffusers 配置 (SERVE_MODE=diffusers) ===
      - OFFLOAD_DIT=0             # 1=启用 transformer 逐块 offload (24GB 卡)
      - DIFFUSERS_PORT=8000
      
      # === 权重管理 ===
      - AUTO_DOWNLOAD_WEIGHTS=1   # 1=自动下载, 0=手动挂载
      # - HF_TOKEN=hf_xxxxx       # Hugging Face token (可选)
      # - HF_ENDPOINT=https://hf-mirror.com  # 国内镜像 (可选)
    
    restart: unless-stopped
```

启动:
```bash
docker-compose up -d
docker-compose logs -f
```

## 📋 环境变量完整列表

### 通用配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SERVE_MODE` | `sglang` | 推理模式: `sglang`（快）或 `diffusers`（24GB 友好） |
| `AUTO_DOWNLOAD_WEIGHTS` | `0` | 自动下载权重: `1`=启用, `0`=手动挂载 |
| `HF_TOKEN` | - | Hugging Face 访问令牌（可选，门禁模型需要） |
| `HF_ENDPOINT` | `https://huggingface.co` | HF 镜像站（国内可用 `https://hf-mirror.com`） |
| `MODEL_PATH` | `/models` | 模型根目录 |
| `CKPT_DIR` | `/models/ckpts` | 检查点目录 |

### SGLang 模式 (SERVE_MODE=sglang)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NUM_GPUS` | `1` | GPU 数量 (1/2/4/8) |
| `QUANTIZATION` | `fp8` | 量化方式: `fp8`（推荐，sm90+）或 `bf16` |
| `ATTENTION_BACKEND` | `hybrid_window_attn_h3` | 注意力后端（VDN 混合注意力） |
| `PERFORMANCE_MODE` | `speed` | 性能模式: `speed` 或 `quality` |
| `WARMUP_FRAMES` | `345` | 预热帧数 (345=14.4 秒 @ 24fps) |
| `WARMUP_RESOLUTION` | `1344x768` | 预热分辨率 |
| `SGLANG_PORT` | `30010` | SGLang 服务端口 |

### Diffusers 模式 (SERVE_MODE=diffusers)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OFFLOAD_DIT` | `0` | Transformer offload: `1`=逐块流式（24GB 卡用），`0`=全部加载到 GPU |
| `DIFFUSERS_PORT` | `8000` | Diffusers API 端口 |
| `DEVICE` | `cuda` | 设备: `cuda` 或 `cuda:0` |

## 💾 模型权重管理

**镜像不预置权重（约 82GB）**，采用运行时下载或外部挂载策略。

### 权重布局

```
/models/ckpts/
├── h3-base/                # 基础 MiniMax H3 (~72GB)
│   ├── transformer/        # 扩散 Transformer (66GB bf16)
│   ├── video_vae/          # 视频 VAE
│   ├── audio_vae/          # 音频 VAE
│   └── schedulers/
├── stage-b-step-2000/      # VDN-H3-50-step (~4.3GB)
│   ├── linear_branch/      # 线性注意力分支
│   └── adapters/default/   # LoRA 适配器
└── stage-dmd-step-250/     # VDN-H3-8-step (~5.1GB, 默认快速模式)
    ├── linear_branch/
    └── adapters/turbo/     # Turbo LoRA (8 步去噪)
```

### 方式 1: 自动下载（首次启动）

```bash
docker run -d \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  -e HF_TOKEN=hf_your_token_here \
  ...
```

首次启动将下载 ~82GB 权重，耗时 10-30 分钟（取决于网速）。下载完成后标记为 `.download_complete`，后续启动跳过下载。

**国内镜像加速**:
```bash
-e HF_ENDPOINT=https://hf-mirror.com
```

### 方式 2: 手动预下载权重

宿主机预先下载:
```bash
mkdir -p ./models/ckpts
hf download OpenVDN/vdn-minimax-h3 --local-dir ./models/ckpts

# 或使用 ModelScope (国内)
modelscope download --model OpenVDN/vdn-minimax-h3 --local_dir ./models/ckpts
```

然后挂载到容器:
```bash
docker run -d \
  -v $(pwd)/models:/models \
  -e AUTO_DOWNLOAD_WEIGHTS=0 \
  ...
```

### 方式 3: 容器内手动下载

```bash
# 进入容器
docker exec -it vdn-h3 bash

# 执行下载脚本
/usr/local/bin/download_weights.sh
```

## 🖥️ 硬件需求与建议

### 最低配置（Diffusers 模式 + offload）

| 组件 | 最低要求 |
|------|---------|
| **GPU** | RTX 4090 / A6000 (24GB) |
| **显存** | 24 GB |
| **系统内存** | 32 GB |
| **磁盘空间** | 100 GB (含权重) |

**性能**: 8 步去噪 ~13-16 秒/评估（transformer 逐块流式，峰值 22GB）

### 推荐配置（SGLang 单卡）

| 组件 | 推荐 |
|------|-----|
| **GPU** | H200 / A100-80GB / RTX 5090 (32GB) |
| **显存** | 32 GB+ |
| **系统内存** | 64 GB |
| **磁盘空间** | 100 GB |

**性能**: 
- H200 FP8: 8 步去噪 90.5 秒
- B200 FP8: 8 步去噪 51 秒

### 生产环境（SGLang 多卡）

| 配置 | GPU | 性能 (8 步去噪) |
|------|-----|-----------------|
| **最优** | 8×B200 | **6.9 秒** (端到端 ~9 秒) |
| 高性能 | 4×B200 | 13.1 秒 |
| 标准 | 2×B200 | 25.9 秒 |
| 入门 | 8×H200 | 18.3 秒 |

### GPU 架构兼容性

| 架构 | 计算能力 | FlashAttention 4 | 注意力后端 | FP8 支持 |
|------|---------|------------------|-----------|---------|
| **Hopper** (H100/H200) | sm90 | ✅ | FA4 varlen + cuDNN | ✅ |
| **Blackwell 数据中心** (B100/B200) | sm100/sm110 | ✅ | FA4 varlen + cuDNN | ✅ |
| **Ampere** (A100/A6000) | sm80 | ❌ | PyTorch varlen_attn | ✅ |
| **Ada** (RTX 4090) | sm89 | ❌ | PyTorch varlen_attn | ✅ |
| **Blackwell 消费级** (RTX 5090) | sm120 | ❌ | FlexAttention Triton | ✅ |

**注意**: FlashAttention 4 仅在 Hopper 和数据中心 Blackwell 使用；Ampere/Ada/RTX 50 系列自动回退到 PyTorch 或 FlexAttention Triton 内核，**无需 FA4 也能正常运行**。

## 🎨 使用示例

### T2VA（文本生成视频）

```bash
# SGLang API
curl -X POST http://localhost:30010/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "一只可爱的橘猫在公园里追逐蝴蝶，阳光明媚，画面温馨",
    "num_frames": 345,
    "num_inference_steps": 8,
    "seed": 42
  }'

# Diffusers API
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "夜晚的都市街道，霓虹灯闪烁，行人匆匆，赛博朋克风格",
    "num_frames": 240,
    "num_inference_steps": 9
  }'
```

### I2VA / FL2VA（关键帧生成视频）

将图像放入 `/input` 目录，然后:

```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "从平静的湖面到壮丽的日落",
    "first_frame": "/input/lake.png",
    "last_frame": "/input/sunset.png",
    "num_frames": 345,
    "num_inference_steps": 9
  }'
```

## 🛠️ 高级操作

### 进入容器 Shell

```bash
docker exec -it vdn-h3 bash
```

### 查看日志

```bash
docker logs -f vdn-h3
```

### 手动执行推理（原生 VDN 脚本）

进入容器后:

```bash
cd /opt/vdn

# Diffusers 脚本推理
python src/inference/infer_diffusers.py "一只可爱的熊猫在吃竹子" \
  --out /output/panda.mp4 \
  --steps 8 \
  --frames 345

# 多 GPU Ulysses 推理（8 卡）
torchrun --standalone --nproc_per_node=8 \
  src/inference/infer_ulysses.py \
  --config configs/inference/8nfe_tuned_fp8_ulysses_b200.yaml \
  checkpoint=/models/ckpts/stage-dmd-step-250 \
  render.prompt_file=prompts/example_0.pt \
  render.out=/output/result.mp4
```

### 编码自定义提示词

```bash
docker exec -it vdn-h3 bash
cd /opt/vdn

# 编码文本提示词
python src/inference/encode_prompt.py \
  --prompt "你的提示词" \
  --out prompts/my_prompt.pt

# 编码带关键帧的提示词（FL2VA）
python src/inference/encode_keyframes.py \
  --prompt "你的提示词" \
  --first /input/first.png \
  --last /input/last.png \
  --out prompts/my_fl2va.pt

# 编码参考图像提示词（Ref2VA-like）
python src/inference/encode_keyframes.py \
  --prompt "你的提示词（需包含 <Picture 1> 等标记）" \
  --refs /input/ref1.png /input/ref2.png /input/ref3.png \
  --out prompts/my_ref2va.pt
```

### 切换检查点（50 步 vs 8 步）

默认使用 `stage-dmd-step-250`（8 步，最快）。切换到 50 步质量模式:

```bash
# 方式 1: 修改 Diffusers 加载参数（需进容器手动调整）
# 方式 2: 挂载时覆盖默认目录软链接
ln -sf /models/ckpts/stage-b-step-2000 /models/ckpts/default

# 重启容器
docker restart vdn-h3
```

## 🔍 健康检查与监控

### 健康检查端点

```bash
# SGLang
curl http://localhost:30010/health

# Diffusers
curl http://localhost:8000/health
```

### GPU 监控

```bash
# 容器内
docker exec vdn-h3 nvidia-smi

# 实时监控
watch -n 1 'docker exec vdn-h3 nvidia-smi'
```

### 显存使用监控

```bash
# Diffusers API 返回显存状态
curl http://localhost:8000/health | jq '.memory_allocated_gb, .memory_reserved_gb'
```

## 🐛 故障排除

### 容器启动失败

```bash
# 查看详细日志
docker logs vdn-h3

# 检查 GPU 可用性
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

### 显存不足（OOM）

**SGLang 模式**:
- 减少 `NUM_GPUS`（单卡改为双卡分布式）
- 确保 `QUANTIZATION=fp8`（默认）

**Diffusers 模式**:
- 启用 offload: `-e OFFLOAD_DIT=1`
- 减少帧数: `num_frames=240` 或 `num_frames=120`
- 确保使用 fp8: `-e QUANTIZATION=fp8`

### 权重下载失败

**问题**: HF 连接超时或慢

**解决**:
```bash
# 使用国内镜像
-e HF_ENDPOINT=https://hf-mirror.com

# 或使用 ModelScope
docker exec -it vdn-h3 bash
modelscope download --model OpenVDN/vdn-minimax-h3 --local_dir /models/ckpts
```

### FlashAttention 4 安装失败

**非问题**: FA4 在 Ampere/Ada/RTX 50 系列是可选的，安装失败不影响运行。镜像会优雅回退到 PyTorch 或 FlexAttention Triton 内核。

### SGLang API 无响应

检查:
1. 端口映射: `-p 30010:30010`
2. 首次请求需预热（warmup），可能需要 30-60 秒
3. 查看日志: `docker logs -f vdn-h3`

## 📦 构建自定义镜像

如需修改或扩展:

```bash
# 克隆仓库
git clone https://github.com/gpurun/ai-images.git
cd ai-images

# 构建依赖链
./scripts/build.sh bases/cuda-runtime
./scripts/build.sh bases/python-ml-cu129
./scripts/build.sh engines/vdn-serve
./scripts/build.sh products/video-vdn-minimax-h3

# 本地标签
docker tag product/video-vdn-minimax-h3:v1 my-custom:latest
```

## 📖 相关链接

- **模型卡片**: [OpenVDN/vdn-minimax-h3](https://huggingface.co/OpenVDN/vdn-minimax-h3)
- **OpenVDN 仓库**: [github.com/OpenVDN/vdn-minimax-h3](https://github.com/OpenVDN/vdn-minimax-h3)
- **MiniMax H3 官方**: [MiniMaxAI/MiniMax-H3](https://huggingface.co/MiniMaxAI/MiniMax-H3)
- **SGLang 文档**: [SGLang Diffusion](https://github.com/sgl-project/sglang)
- **论文**: [Video DeltaNet (arXiv:2609.20744)](https://arxiv.org/abs/2609.20744)
- **博客**: [OpenVDN 官方博客](https://openvdn.github.io/)

## 📄 许可证

- **本镜像代码**: Apache 2.0
- **VDN-H3 模型权重**: MiniMax H3 社区许可协议（派生模型）
- **重要限制**:
  - 地域限制: 欧盟、英国、韩国、美国需单独授权
  - 商业使用: 年收入超过 2000 万美元需联系 MiniMax (api@minimax.io)
  - 详见 [LICENSE](LICENSE) 和 [NOTICE](NOTICE) 文件
- **VDN 推理代码**: Apache 2.0
- **Qwen3-VL 编码器**: Apache 2.0

---

**维护**: GPURun Team  
**更新**: 2026-09-23  
**版本**: v1
