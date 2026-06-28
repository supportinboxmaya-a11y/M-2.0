"""
Maya 2.0 - Settings
--------------------
Central configuration with validation and type safety.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file
load_dotenv()

BASE_DIR = Path(__file__).parent.parent

# API Keys
GROQ_KEY = os.environ.get("GROQ_KEY", "")
GEMINI_KEY = os.environ.get("GEMINI_KEY", "")
OPENAI_KEY = os.environ.get("OPENAI_KEY", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_KEY", "")
DEEPSEEK_KEY = os.environ.get("DEEPSEEK_KEY", "")

# Models
PRIMARY_MODEL = os.environ.get("PRIMARY_MODEL", "llama-3.3-70b-versatile")
FALLBACK_MODEL = os.environ.get("FALLBACK_MODEL", "gemini-1.5-flash")

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
    keys = [GROQ_KEY, GEMINI_KEY, OPENAI_KEY, ANTHROPIC_KEY, DEEPSEEK_KEY]
    if not any(keys):
        print("WARNING: No API keys found! Set at least one in .env file.")
        print("  Get free Groq key at: console.groq.com")
        print("  Get free Gemini key at: aistudio.google.com")
        return False
    return True

validate()
