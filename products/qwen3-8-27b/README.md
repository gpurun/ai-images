# Qwen3-8-27B

用于构建并部署 Qwen3 系列 8B/27B 的容器化镜像（SGLang/vLLM），默认示例使用 `Qwen/Qwen3-8B`，可按需修改 `.env` 中的 `MODEL_PATH` 切换至 `Qwen/Qwen3-14B`、`Qwen/Qwen3-32B` 等。

## 快速开始
```bash
cd products/qwen3-8-27b
cp .env.example .env
# 修改 MODEL_PATH/SERVED_MODEL_NAME/TP_SIZE 等
docker compose -f docker-compose.sglang.yaml up -d --build
# 或
docker compose -f docker-compose.vllm.yaml up -d --build
```

## 验证
```bash
curl http://127.0.0.1:30000/v1/models  # SGLang
curl http://127.0.0.1:8000/v1/models   # vLLM
```
