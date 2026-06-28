"""
Maya 2.0 - Ultra Logger
------------------------
Loguru based powerful logging system.
"""

import os
import sys
from pathlib import Path
from loguru import logger as _logger

# Log directory
BASE_DIR = Path(__file__).parent.parent
LOG_DIR = BASE_DIR / "storage" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

# Log level from env
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()

# Remove default handler
_logger.remove()

# Console handler - colored, readable
_logger.add(
    sys.stdout,
    level=LOG_LEVEL,
    colorize=True,
    format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[module]}</cyan> | <level>{message}</level>",
    filter=lambda r: True
)

# File handler - full details
_logger.add(
    str(LOG_DIR / "maya.log"),
    level="DEBUG",
    rotation="10 MB",
    retention="7 days",
    compression="zip",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[module]} | {message}",
    encoding="utf-8"
)

# Error file handler
_logger.add(
    str(LOG_DIR / "errors.log"),
    level="ERROR",
    rotation="5 MB",
    retention="30 days",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {extra[module]} | {message}\n{exception}",
    encoding="utf-8"
)


def get_logger(module: str):
    """Get a logger for a specific module."""
    return _logger.bind(module=module)


# Default logger
maya_logger = get_logger("maya")
