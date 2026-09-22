#!/usr/bin/env python3
"""
FastAPI server for Qwen-Image-2.1 (or other diffusers pipelines).
Endpoints: /generate (t2i), /edit (optional), /health
"""
import os
import io
import base64
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field
import torch
from PIL import Image

# Global pipeline holder
pipeline = None


class GenerateRequest(BaseModel):
    prompt: str = Field(..., description="Text prompt for image generation")
    negative_prompt: Optional[str] = Field(None, description="Negative prompt")
    width: Optional[int] = Field(1024, ge=256, le=4096)
    height: Optional[int] = Field(1024, ge=256, le=4096)
    num_inference_steps: Optional[int] = Field(28, ge=1, le=100)
    guidance_scale: Optional[float] = Field(7.0, ge=1.0, le=20.0)
    seed: Optional[int] = Field(None, description="Random seed for reproducibility")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load pipeline on startup, cleanup on shutdown."""
    global pipeline
    
    model_path = os.getenv("MODEL_PATH", "Qwen/Qwen-Image-2.1")
    variant = os.getenv("VARIANT", "4090-24g")
    torch_dtype_str = os.getenv("TORCH_DTYPE", "auto")
    enable_cpu_offload = os.getenv("ENABLE_CPU_OFFLOAD", "0") == "1"
    
    # Determine torch_dtype
    if torch_dtype_str == "auto":
        torch_dtype = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
    elif torch_dtype_str == "bf16":
        torch_dtype = torch.bfloat16
    elif torch_dtype_str == "fp16":
        torch_dtype = torch.float16
    elif torch_dtype_str == "fp8":
        # FP8 requires special handling; for now map to fp16 and note in logs
        print("FP8 requested but not fully implemented; using fp16 with potential quantization")
        torch_dtype = torch.float16
    else:
        torch_dtype = torch.float32
    
    print(f"Loading pipeline: {model_path}, variant={variant}, dtype={torch_dtype}")
    
    try:
        from diffusers import QwenImage21Pipeline
        
        pipeline = QwenImage21Pipeline.from_pretrained(
            model_path,
            torch_dtype=torch_dtype,
            low_cpu_mem_usage=True,
        )
        
        if enable_cpu_offload:
            print("Enabling model CPU offload for lower VRAM usage")
            pipeline.enable_model_cpu_offload()
        else:
            pipeline = pipeline.to("cuda")
        
        print(f"Pipeline loaded successfully on device: {pipeline.device}")
    except Exception as e:
        print(f"ERROR loading pipeline: {e}")
        raise
    
    yield
    
    # Cleanup
    del pipeline
    torch.cuda.empty_cache()


app = FastAPI(
    title="Diffusers API - Qwen-Image-2.1",
    description="HTTP API for image generation using diffusers pipelines",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    """Health check endpoint."""
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not loaded")
    return {"status": "healthy", "model": os.getenv("MODEL_PATH", "unknown")}


@app.post("/generate")
async def generate(request: GenerateRequest):
    """Generate image from text prompt."""
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not loaded")
    
    try:
        # Set seed if provided
        generator = None
        if request.seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(request.seed)
        
        # Generate image
        result = pipeline(
            prompt=request.prompt,
            negative_prompt=request.negative_prompt,
            width=request.width,
            height=request.height,
            num_inference_steps=request.num_inference_steps,
            guidance_scale=request.guidance_scale,
            generator=generator,
        )
        
        image = result.images[0]
        
        # Convert to base64
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        img_bytes = buffer.getvalue()
        img_base64 = base64.b64encode(img_bytes).decode("utf-8")
        
        return {
            "image": img_base64,
            "format": "png",
            "width": image.width,
            "height": image.height,
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "service": "Diffusers API",
        "model": os.getenv("MODEL_PATH", "Qwen/Qwen-Image-2.1"),
        "variant": os.getenv("VARIANT", "unknown"),
        "endpoints": {
            "generate": "POST /generate",
            "health": "GET /health",
        },
    }


if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    
    uvicorn.run(app, host=host, port=port, log_level="info")
