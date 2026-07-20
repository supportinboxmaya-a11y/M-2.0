
"""
Maya 2.0 - Settings
-------------------
Central configuration with validation and type safety.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file
load_dotenv()

BASE_DIR = Path(__file__).parent.parent


def env_first(*names: str, default: str = "") -> str:
    """Return first non-empty env var among names (supports *_KEY and *_API_KEY)."""
    for name in names:
        value = os.environ.get(name, "")
        if value:
            return value
    return default


# API Keys (dual-read mapping to Render Environment Variables)
GROQ_KEY = env_first("GROQ_API_KEY", "GROQ_KEY")
GEMINI_KEY = env_first("GEMINI_API_KEY", "GEMINI_KEY")
OPENAI_KEY = env_first("OPENAI_API_KEY", "OPENAI_KEY")
ANTHROPIC_KEY = env_first("ANTHROPIC_API_KEY", "ANTHROPIC_KEY")
DEEPSEEK_KEY = env_first("DEEPSEEK_API_KEY", "DEEPSEEK_KEY")
OPENROUTER_KEY = env_first("OPENROUTER_API_KEY", "OPENROUTER_KEY")
CEREBRAS_KEY = env_first("CEREBRAS_API_KEY", "CEREBRAS_KEY")
NVIDIA_NIM_KEY = env_first("NVIDIA_NIM_API_KEY", "NVIDIA_NIM_KEY")

# Models
PRIMARY_MODEL = os.environ.get("PRIMARY_MODEL", "openai/gpt-oss-120b")
FALLBACK_MODEL = os.environ.get("FALLBACK_MODEL", "gemini-flash-latest")

# Agent settings
MAX_STEPS = int(os.environ.get("MAX_STEPS", "25"))
MAX_TOKENS = int(os.environ.get("MAX_TOKENS", "8000"))
TIMEOUT = int(os.environ.get("TIMEOUT", "60"))
BUDGET_USD = float(os.environ.get("BUDGET_USD", "1.0"))
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"

# Storage
STORAGE_DIR = BASE_DIR / "storage"
MEMORY_DIR = STORAGE_DIR / "memory"
WORKSPACE_DIR = BASE_DIR / "workspace"
LOG_DIR = STORAGE_DIR / "logs"
BACKUP_DIR = STORAGE_DIR / "backups"
DB_FILE = str(MEMORY_DIR / "maya.db")

# Create directories
for d in [STORAGE_DIR, MEMORY_DIR, WORKSPACE_DIR, LOG_DIR, BACKUP_DIR]:
    d.mkdir(parents=True, exist_ok=True)


# Validation
def validate():
    """Check at least one LLM provider is configured."""
    keys = [
        GROQ_KEY,
        GEMINI_KEY,
        OPENAI_KEY,
        ANTHROPIC_KEY,
        DEEPSEEK_KEY,
        OPENROUTER_KEY,
        CEREBRAS_KEY,
        NVIDIA_NIM_KEY,
    ]
    if not any(keys):
        print("WARNING: No API keys found! Set at least one in .env file.")
        print("  Get free Groq key at: console.groq.com")
        print("  Get free Gemini key at: aistudio.google.com")
        return False
    return True


validate()
