from .logger import get_logger
log = get_logger("tools")

def log_tool_call(tool: str, inputs: dict): log.info(f"Tool: {tool} | inputs={str(inputs)[:100]}")
def log_tool_result(tool: str, success: bool, elapsed: float = 0): log.info(f"Tool result: {tool} | {'OK' if success else 'FAIL'} | {elapsed:.2f}s")
def log_tool_error(tool: str, error: str): log.error(f"Tool error [{tool}]: {error}")
