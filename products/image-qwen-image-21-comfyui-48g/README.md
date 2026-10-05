# image-qwen-image-21-comfyui-48g

本产品是 **Qwen-Image-2.1 图像生成系列**的一部分。

📖 **完整文档**: [../_qwen-image-21-shared/README.md](../_qwen-image-21-shared/README.md)

## 🖥️ GPU 卡型、数量及硬件要求

| 项目 | 要求 |
|---|---|
| GPU 型号 | NVIDIA A100-80GB / H100-80GB（48GB+ 卡） |
| 显存 | 48 GB+ |
| GPU 数量 | **1 卡** |
| 精度 | BF16 full |
| 默认分辨率 | 2048×2048 |
| 内存（RAM） | >= 32 GB（48g SKU 建议 >= 64 GB） |
| 数据盘（权重缓存） | >= 40 GB |
| 共享内存（SHM） | >= 32 GB |

## 🌍 环境要求

| 项目 | 推荐版本 | 说明 |
|---|---|---|
| 操作系统 | Ubuntu 22.04 LTS / 24.04 LTS | Linux 环境最佳 |
| NVIDIA 驱动 | >= 535.129.03（RTX 5090 需 >= 570.xx） | Blackwell 需更新驱动 |
| CUDA | 12.8.x | 镜像基于 CUDA 12.8 构建 |
| Docker | >= 24.0 | 容器运行时 |
| NVIDIA Container Toolkit | >= 1.15.0 | GPU 透传 |


## 🚀 快速启动

```bash
docker run -d --gpus all \
  -p 8188:8188 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-comfyui-48g:v1
```

**ComfyUI 访问**: http://localhost:8188

---

详细使用说明、API 文档、环境变量、性能对比、故障排除等请查看 [共享文档](../_qwen-image-21-shared/README.md)。
