"""
Maya 2.0 - Logger
------------------
Loguru based logging system.
"""

import os
import sys
from pathlib import Path

try:
    from loguru import logger as _logger
    LOGURU_AVAILABLE = True
except ImportError:
    LOGURU_AVAILABLE = False

BASE_DIR = Path(__file__).parent.parent
LOG_DIR = BASE_DIR / "storage" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()

if LOGURU_AVAILABLE:
    _logger.remove()
    _logger.add(
        sys.stdout,
        level=LOG_LEVEL,
        colorize=True,
        format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[module]}</cyan> | <level>{message}</level>",
    )
    _logger.add(
        str(LOG_DIR / "maya.log"),
        level="DEBUG",
        rotation="10 MB",
        retention="7 days",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[module]} | {message}",
        encoding="utf-8"
    )

    def get_logger(module: str):
        return _logger.bind(module=module)

    maya_logger = get_logger("maya")

else:
    import logging as _std_logging

    class _FallbackLogger:
        def __init__(self, module):
            self._log = _std_logging.getLogger(module)
            _std_logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s | %(levelname)s | %(name)s | %(message)s")

        def info(self, msg): self._log.info(msg)
        def debug(self, msg): self._log.debug(msg)
        def warning(self, msg): self._log.warning(msg)
        def error(self, msg): self._log.error(msg)
        def critical(self, msg): self._log.critical(msg)

    def get_logger(module: str):
        return _FallbackLogger(module)

    maya_logger = get_logger("maya")
