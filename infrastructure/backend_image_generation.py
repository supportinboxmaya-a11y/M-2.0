"""
Image Generation Module for Maya Ultra
Uses Pollinations.ai (free, no API key required) and HuggingFace
"""

import os
import httpx
import base64
import io
import logging
import random
import urllib.parse
from typing import Optional, List, Dict
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import Optional, List
from fastapi import APIRouter, HTTPException, Depends
from datetime import datetime

logger = logging.getLogger(__name__)

# Router for image generation endpoints - NO prefix here, added in app.include_router()
router = APIRouter(tags=["image"])

class ImageGenerationRequest(BaseModel):
    prompt: str
    width: int = 1024
    height: int = 1024
    model: str = "flux"  # flux, gptimage, dall-e-3, midjourney
    seed: Optional[int] = None
    n: int = 1
    enhance_prompt: bool = True
    transparent: bool = False
    format: str = "webp"  # webp, png, jpg

class ImageGenerationResponse(BaseModel):
    success: bool
    images: List[str]  # URLs or base64
    prompt: str
    enhanced_prompt: Optional[str] = None
    model: str
    seed: Optional[int] = None
    error: Optional[str] = None

class ImageEditRequest(BaseModel):
    image: str  # base64 or URL
    prompt: str
    mask: Optional[str] = None  # base64 mask for inpainting
    strength: float = 0.8

class ImageVariationRequest(BaseModel):
    image: str  # base64 or URL
    n: int = 3
    strength: float = 0.7

# Pollinations.ai integration (free, no API key)
class PollinationsImageGenerator:
    BASE_URL = "https://image.pollinations.ai/prompt"
    
    @staticmethod
    def generate_url(prompt: str, width: int = 1024, height: int = 1024, 
                     model: str = "flux", seed: Optional[int] = None,
                     enhance: bool = True, transparent: bool = False,
                     format: str = "webp") -> str:
        """Generate image URL from Pollinations.ai"""
        params = {
            "width": width,
            "height": height,
            "model": model,
            "enhance": "true" if enhance else "false",
            "transparent": "true" if transparent else "false",
            "format": format,
        }
        if seed:
            params["seed"] = seed
        
        # URL encode the prompt
        import urllib.parse
        encoded_prompt = urllib.parse.quote(prompt)
        
        # Build query string
        query = "&".join([f"{k}={v}" for k, v in params.items()])
        return f"https://image.pollinations.ai/prompt/{encoded_prompt}?{query}"
    
    @staticmethod
    async def generate(prompt: str, width: int = 1024, height: int = 1024,
                       model: str = "flux", seed: Optional[int] = None,
                       n: int = 1, enhance: bool = True, transparent: bool = False,
                       format: str = "webp") -> List[str]:
        """Generate images using Pollinations.ai"""
        urls = []
        for i in range(n):
            seed_val = seed if seed else None
            if n > 1 and not seed:
                # Generate different seed for each variation
                import random
                seed_val = random.randint(0, 2**32 - 1)
            url = PollinationsImageGenerator.generate_url(
                prompt, width, height, model, seed_val, True, False, "webp"
            )
            urls.append(url)
        return urls

# HuggingFace Inference API (free tier available)
class HuggingFaceImageGenerator:
    def __init__(self):
        self.api_key = os.getenv("HUGGINGFACE_API_KEY", "")
        self.base_url = "https://api-inference.huggingface.co/models"
    
    async def generate(self, prompt: str, model: str = "black-forest-labs/FLUX.1-schnell",
                       width: int = 1024, height: int = 1024, n: int = 1) -> List[str]:
        """Generate images using HuggingFace Inference API"""
        if not self.api_key:
            raise ValueError("HUGGINGFACE_API_KEY not set")
        
        headers = {"Authorization": f"Bearer {self.api_key}"}
        urls = []
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            for i in range(n):
                payload = {
                    "inputs": prompt,
                    "parameters": {
                        "width": width,
                        "height": height,
                        "num_inference_steps": 4,
                        "guidance_scale": 0.0
                    }
                }
                try:
                    response = await client.post(
                        f"{self.base_url}/{model}",
                        headers=headers,
                        json=payload
                    )
                    if response.status_code == 200:
                        # Response is image bytes
                        import base64
                        img_b64 = base64.b64encode(response.content).decode()
                        urls.append(f"data:image/png;base64,{img_b64}")
                    else:
                        logger.error(f"HF API error: {response.status_code} - {response.text}")
                except Exception as e:
                    logger.error(f"HF generation error: {e}")
        return urls

# Main image generation service
class ImageGenerationService:
    def __init__(self):
        self.pollinations = PollinationsImageGenerator()
        self.huggingface = HuggingFaceImageGenerator() if os.getenv("HUGGINGFACE_API_KEY") else None
    
    async def generate(self, request) -> dict:
        """Generate images using the best available provider"""
        
        # Try Pollinations first (free, no API key)
        try:
            logger.info(f"Generating image with Pollinations: {request.prompt[:50]}...")
            urls = await self.pollinations.generate(
                prompt=request.prompt,
                width=request.width,
                height=request.height,
                model=request.model,
                seed=request.seed,
                n=request.n,
                enhance=request.enhance_prompt,
                transparent=request.transparent,
                format=request.format
            )
            
            if urls:
                return {
                    "success": True,
                    "images": urls,
                    "prompt": request.prompt,
                    "model": request.model,
                    "seed": request.seed
                }
        except Exception as e:
            logger.warning(f"Pollinations failed: {e}")
        
        # Fallback to HuggingFace if available
        if self.huggingface:
            try:
                logger.info(f"Falling back to HuggingFace...")
                urls = await self.huggingface.generate(
                    prompt=request.prompt,
                    width=request.width,
                    height=request.height,
                    n=request.n
                )
                if urls:
                    return {
                        "success": True,
                        "images": urls,
                        "prompt": request.prompt,
                        "model": "huggingface",
                        "seed": request.seed
                    }
            except Exception as e:
                logger.warning(f"HuggingFace failed: {e}")
        
        return {
            "success": False,
            "images": [],
            "prompt": request.prompt,
            "model": request.model,
            "error": "All image generation providers failed"
        }
    
    async def edit_image(self, request) -> dict:
        """Edit image using inpainting/outpainting"""
        # For now, use Pollinations with edit prompt
        edit_prompt = f"edit: {request.prompt}, image: {request.image}"
        urls = await self.pollinations.generate(
            prompt=edit_prompt,
            model="gptimage",  # gptimage supports editing
            n=1
        )
        return {
            "success": len(urls) > 0,
            "images": urls,
            "prompt": request.prompt
        }
    
    async def create_variations(self, request) -> dict:
        """Create variations of an image"""
        var_prompt = f"variation: {request.image}, strength: {request.strength}"
        urls = await self.pollinations.generate(
            prompt=var_prompt,
            n=request.n,
            model="flux"
        )
        return {
            "success": len(urls) > 0,
            "images": urls,
            "prompt": f"Variations of image"
        }

# Create global service instance
image_service = ImageGenerationService()

# API Endpoints - use lazy import for get_current_user to avoid circular imports
def get_current_user_lazy():
    from api import get_current_user
    return get_current_user

@router.post("/generate")
async def generate_image(request: ImageGenerationRequest, user=Depends(get_current_user_lazy)):
    """Generate images from text prompt"""
    try:
        result = await image_service.generate(request)
        return result
    except Exception as e:
        logger.error(f"Image generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/edit")
async def edit_image(request: ImageEditRequest, user=Depends(get_current_user_lazy)):
    """Edit image using inpainting/outpainting"""
    try:
        result = await image_service.edit_image(request)
        return result
    except Exception as e:
        logger.error(f"Image edit error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/variations")
async def create_variations(request: ImageVariationRequest, user=Depends(get_current_user_lazy)):
    """Create variations of an image"""
    try:
        result = await image_service.create_variations(request)
        return result
    except Exception as e:
        logger.error(f"Variations error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/models")
async def list_models(user=Depends(get_current_user_lazy)):
    """List available image generation models"""
    return {
        "models": [
            {"id": "flux", "name": "Flux (Fast, High Quality)", "provider": "Pollinations", "free": True},
            {"id": "gptimage", "name": "GPT-Image (Editing)", "provider": "Pollinations", "free": True},
            {"id": "dall-e-3", "name": "DALL-E 3 (High Quality)", "provider": "Pollinations", "free": True},
            {"id": "midjourney", "name": "Midjourney Style", "provider": "Pollinations", "free": True},
            {"id": "flux-schnell", "name": "FLUX.1-schnell (Fast)", "provider": "HuggingFace", "free": True, "requires_key": True},
            {"id": "flux-dev", "name": "FLUX.1-dev (Quality)", "provider": "HuggingFace", "free": True, "requires_key": True},
            {"id": "sdxl", "name": "SDXL (Stable Diffusion)", "provider": "HuggingFace", "free": True, "requires_key": True},
        ]
    }

@router.get("/models")
async def list_models(user=Depends(get_current_user_lazy)):
    """List available image generation models"""
    return {
        "models": [
            {"id": "flux", "name": "Flux (Fast, High Quality)", "provider": "Pollinations", "free": True},
            {"id": "gptimage", "name": "GPT-Image (Editing)", "provider": "Pollinations", "free": True},
            {"id": "dall-e-3", "name": "DALL-E 3 (High Quality)", "provider": "Pollinations", "free": True},
            {"id": "midjourney", "name": "Midjourney Style", "provider": "Pollinations", "free": True},
            {"id": "flux-schnell", "name": "FLUX.1-schnell (Fast)", "provider": "HuggingFace", "free": True, "requires_key": True},
            {"id": "flux-dev", "name": "FLUX.1-dev (Quality)", "provider": "HuggingFace", "free": True, "requires_key": True},
            {"id": "sdxl", "name": "SDXL (Stable Diffusion)", "provider": "HuggingFace", "free": True, "requires_key": True},
        ]
    }
