# image-qwen-image-21-diffusers-48g

本产品是 **Qwen-Image-2.1 图像生成系列**的一部分。

📖 **完整文档**: [../_qwen-image-21-shared/README.md](../_qwen-image-21-shared/README.md)

## 🚀 快速启动

```bash
docker run -d --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/models \
  -v $(pwd)/output:/output \
  -e AUTO_DOWNLOAD_WEIGHTS=1 \
  ghcr.io/gpurun/product/image-qwen-image-21-diffusers-48g:v1
```

**API 访问**: http://localhost:8000/generate

---

详细使用说明、API 文档、环境变量、性能对比、故障排除等请查看 [共享文档](../_qwen-image-21-shared/README.md)。
