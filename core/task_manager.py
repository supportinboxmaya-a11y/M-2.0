import uuid
from typing import List, Dict, Optional
from config.models import TaskModel, StepModel
from config.constants import *

class TaskManager:
    """Manages task lifecycle."""

    def __init__(self):
        self.tasks: Dict[str, TaskModel] = {}
        self.current_task: Optional[str] = None

    def create_task(self, goal: str) -> TaskModel:
        task_id = str(uuid.uuid4())[:8]
        task = TaskModel(id=task_id, goal=goal, status=TASK_PENDING)
        self.tasks[task_id] = task
        self.current_task = task_id
        return task

    def update_status(self, task_id: str, status: str, result: str = None, error: str = None):
        if task_id in self.tasks:
            self.tasks[task_id].status = status
            if result:
                self.tasks[task_id].result = result
            if error:
                self.tasks[task_id].error = error

    def get_task(self, task_id: str) -> Optional[TaskModel]:
        return self.tasks.get(task_id)

    def all_tasks(self) -> List[TaskModel]:
        return list(self.tasks.values())

    def increment_retry(self, task_id: str):
        if task_id in self.tasks:
            self.tasks[task_id].retries += 1
