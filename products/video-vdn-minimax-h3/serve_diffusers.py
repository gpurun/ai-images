#!/usr/bin/env python3
"""
VDN-MiniMax-H3 Diffusers HTTP API Server
FastAPI-based HTTP server wrapping diffusers ModularPipeline for single-GPU inference (24GB-friendly).
Optimized for RTX 4090 / 5090 with fp8 + offload support.
"""
import argparse
import logging
import os
import sys
from pathlib import Path
from typing import Optional, List

import torch
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel, Field
from accelerate import cpu_offload_with_hook
from diffusers import ModularPipeline
from diffusers.hooks import apply_group_offloading

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="VDN-MiniMax-H3 Diffusers API",
    description="Video generation API for OpenVDN VDN-H3 via Diffusers ModularPipeline",
    version="1.0.0"
)

# Global pipeline instance
pipeline = None
config = None


class GenerateRequest(BaseModel):
    """Video generation request"""
    prompt: str = Field(..., description="Text prompt for video generation")
    num_frames: int = Field(345, ge=120, le=360, description="Number of frames (120-360, snapped to 17n+5)")
    num_inference_steps: int = Field(9, ge=2, le=51, description="Number of inference steps (9 for 8-step, 51 for 50-step)")
    seed: Optional[int] = Field(None, description="Random seed for reproducibility")
    first_frame: Optional[str] = Field(None, description="Path to first keyframe image (I2VA / FL2VA)")
    last_frame: Optional[str] = Field(None, description="Path to last keyframe image (L2VA / FL2VA)")
    output_path: Optional[str] = Field(None, description="Custom output path (default: /output/video_{timestamp}.mp4)")
    

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    model: str
    device: str
    memory_allocated_gb: float
    memory_reserved_gb: float


def load_pipeline(
    model_path: str = "OpenVDN/vdn-minimax-h3",
    workflow: str = "t2va",
    fp8: bool = True,
    offload_dit: bool = False,
    device: str = "cuda"
):
    """Load VDN-H3 diffusers pipeline with optimizations"""
    logger.info(f"Loading VDN-H3 pipeline: {model_path}, workflow={workflow}, fp8={fp8}, offload_dit={offload_dit}")
    
    pipe = ModularPipeline.from_pretrained(model_path, workflow=workflow)
    
    # Load components with optimizations
    load_kwargs = {
        "trust_remote_code": True,
        "torch_dtype": torch.bfloat16,
    }
    
    if fp8:
        logger.info("Enabling FP8 quantization for transformer")
        load_kwargs["fp8"] = {"transformer": True}
    
    pipe.load_components(**load_kwargs)
    
    # Offload text encoder and VAEs
    logger.info("Applying group offloading for text encoder and VAEs")
    apply_group_offloading(
        pipe.text_encoder, 
        onload_device=device, 
        offload_type="leaf_level",
        use_stream=True
    )
    _, vae = cpu_offload_with_hook(pipe.vae, execution_device=device)
    cpu_offload_with_hook(pipe.audio_vae, execution_device=device, prev_module_hook=vae)
    
    # Handle transformer: on GPU or streamed per block for 24GB cards
    if offload_dit:
        logger.info("Streaming transformer per block (24GB mode)")
        apply_group_offloading(
            pipe.transformer,
            onload_device=device,
            offload_type="block_level",
            num_blocks_per_group=1,
            use_stream=True
        )
    else:
        logger.info("Loading transformer to GPU")
        pipe.transformer.to(device)
    
    logger.info("Pipeline loaded successfully")
    return pipe


@app.on_event("startup")
async def startup_event():
    """Load pipeline on startup"""
    global pipeline, config
    
    logger.info("=" * 80)
    logger.info("VDN-MiniMax-H3 Diffusers API Server Starting")
    logger.info("=" * 80)
    
    # Parse config from environment
    model_path = os.getenv("MODEL_PATH", "OpenVDN/vdn-minimax-h3")
    fp8 = os.getenv("QUANTIZATION", "fp8").lower() == "fp8"
    offload_dit = os.getenv("OFFLOAD_DIT", "0") == "1"
    device = os.getenv("DEVICE", "cuda")
    
    config = {
        "model_path": model_path,
        "fp8": fp8,
        "offload_dit": offload_dit,
        "device": device
    }
    
    logger.info(f"Config: {config}")
    
    try:
        pipeline = load_pipeline(
            model_path=model_path,
            fp8=fp8,
            offload_dit=offload_dit,
            device=device
        )
        logger.info("Startup complete, ready to serve requests")
    except Exception as e:
        logger.error(f"Failed to load pipeline: {e}", exc_info=True)
        sys.exit(1)


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint"""
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not loaded")
    
    return HealthResponse(
        status="healthy",
        model=config["model_path"],
        device=config["device"],
        memory_allocated_gb=torch.cuda.memory_allocated() / 1e9,
        memory_reserved_gb=torch.cuda.memory_reserved() / 1e9
    )


@app.post("/generate")
async def generate(request: GenerateRequest):
    """Generate video from prompt"""
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not loaded")
    
    logger.info(f"Generate request: prompt='{request.prompt[:50]}...', frames={request.num_frames}, steps={request.num_inference_steps}")
    
    try:
        # Set random seed if provided
        if request.seed is not None:
            generator = torch.Generator(device=config["device"]).manual_seed(request.seed)
        else:
            generator = None
        
        # Generate video
        output = pipeline(
            prompt=request.prompt,
            num_frames=request.num_frames,
            num_inference_steps=request.num_inference_steps,
            generator=generator,
            output=["videos", "audio", "sampling_rate"]
        )
        
        # Save video
        if request.output_path:
            output_path = Path(request.output_path)
        else:
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = Path("/output") / f"video_{timestamp}.mp4"
        
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Export video (diffusers handles MP4 muxing via av)
        from diffusers.utils.export_utils import export_to_video
        export_to_video(
            output.videos[0],
            str(output_path),
            fps=24,
            audio=output.audio[0] if output.audio else None,
            audio_sampling_rate=output.sampling_rate if output.sampling_rate else None
        )
        
        logger.info(f"Video saved: {output_path} ({output_path.stat().st_size / 1e6:.1f} MB)")
        
        return JSONResponse({
            "status": "success",
            "output_path": str(output_path),
            "num_frames": request.num_frames,
            "inference_steps": request.num_inference_steps,
            "seed": request.seed
        })
        
    except Exception as e:
        logger.error(f"Generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/download/{filename}")
async def download(filename: str):
    """Download generated video"""
    output_path = Path("/output") / filename
    if not output_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(output_path, media_type="video/mp4", filename=filename)


def main():
    parser = argparse.ArgumentParser(description="VDN-MiniMax-H3 Diffusers HTTP API Server")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Server host")
    parser.add_argument("--port", type=int, default=8000, help="Server port")
    args = parser.parse_args()
    
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
