from .logger import get_logger
log = get_logger("errors")

def log_error(module: str, error: str, context: str = ""):
    log.error(f"[{module}] {error}" + (f" | {context[:100]}" if context else ""))

def log_critical(module: str, error: str):
    log.critical(f"[{module}] CRITICAL: {error}")

def log_warning(module: str, warning: str):
    log.warning(f"[{module}] {warning}")
