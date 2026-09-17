from .logger import get_logger
log = get_logger("agent")

def log_task_start(goal: str): log.info(f"Task started: {goal}")
def log_task_done(goal: str, success: bool): log.info(f"Task {'SUCCESS' if success else 'FAILED'}: {goal}")
def log_step(step: str, success: bool = True): log.debug(f"Step {'done' if success else 'failed'}: {step}")
def log_plan(steps: int): log.info(f"Plan created: {steps} steps")
def log_retry(attempt: int, reason: str): log.warning(f"Retry #{attempt}: {reason}")
