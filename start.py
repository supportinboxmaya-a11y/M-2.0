#!/usr/bin/env python3
"""Start Maya 2.0 ULTRA API Server"""
import uvicorn
import os

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=port,
        reload=os.getenv("DEV", "false") == "true",
        log_level="info"
    )
