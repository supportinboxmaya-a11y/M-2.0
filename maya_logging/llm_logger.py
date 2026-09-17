from .logger import get_logger
log = get_logger("llm")

def log_request(provider: str, model: str, tokens: int = 0): log.debug(f"Request -> {provider}/{model} | tokens={tokens}")
def log_response(provider: str, elapsed: float, tokens: int = 0): log.debug(f"Response <- {provider} | {elapsed:.2f}s | tokens={tokens}")
def log_fallback(from_p: str, to_p: str, reason: str): log.warning(f"Fallback: {from_p} -> {to_p} | {reason}")
def log_error(provider: str, error: str): log.error(f"LLM error [{provider}]: {error}")
