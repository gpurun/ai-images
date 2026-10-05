# image-qwen-image-21-diffusers-4090-24g

本产品是 **Qwen-Image-2.1 图像生成系列**的一部分。

📖 **完整文档**: [../_qwen-image-21-shared/README.md](../_qwen-image-21-shared/README.md)

## 🖥️ GPU 卡型、数量及硬件要求

| 项目 | 要求 |
|---|---|
| GPU 型号 | NVIDIA RTX 4090（或同级 24GB 卡） |
| 显存 | 24 GB |
| GPU 数量 | **1 卡** |
| 精度 | FP16/FP8 + CPU offload |
| 默认分辨率 | 1024×1024 |
| 内存（RAM） | >= 32 GB（48g SKU 建议 >= 64 GB） |
| 数据盘（权重缓存） | >= 40 GB |
| 共享内存（SHM） | >= 16 GB |

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
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-4090-24g:v1
```

**API 访问**: http://localhost:8000/generate

---

详细使用说明、API 文档、环境变量、性能对比、故障排除等请查看 [共享文档](../_qwen-image-21-shared/README.md)。
