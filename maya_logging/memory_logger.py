from .logger import get_logger
log = get_logger("memory")

def log_add(memory_type: str, content: str): log.debug(f"Memory add [{memory_type}]: {content[:80]}")
def log_search(query: str, hits: int): log.debug(f"Memory search: '{query}' -> {hits} results")
def log_episode(goal: str, success: bool): log.info(f"Episode saved: {'SUCCESS' if success else 'FAIL'} | {goal[:60]}")
