"""Background task queue (asyncio) with status tracking and error capture."""
import asyncio
import time
import uuid


class TaskQueue:
    def __init__(self, workers: int = 2, max_history: int = 200):
        self._queue: asyncio.Queue = asyncio.Queue()
        self._status: dict[str, dict] = {}
        self._workers = workers
        self._max_history = max_history
        self._running = False

    async def start(self) -> None:
        if self._running:
            return
        self._running = True
        for i in range(self._workers):
            asyncio.create_task(self._worker(i), name=f"taskq-worker-{i}")

    async def submit(self, coro_fn, *args, name: str = "task", **kwargs) -> str:
        """Queue an async callable; returns a task_id for status lookup."""
        task_id = uuid.uuid4().hex[:12]
        self._status[task_id] = {"name": name, "state": "queued",
                                 "queued_at": time.time(), "error": None, "result": None}
        self._trim()
        await self._queue.put((task_id, coro_fn, args, kwargs))
        return task_id

    def status(self, task_id: str) -> dict | None:
        return self._status.get(task_id)

    def all_status(self) -> dict:
        return dict(self._status)

    async def _worker(self, n: int) -> None:
        while True:
            task_id, fn, args, kwargs = await self._queue.get()
            st = self._status.get(task_id, {})
            st.update(state="running", started_at=time.time())
            try:
                result = await fn(*args, **kwargs)
                st.update(state="done", result=result, finished_at=time.time())
            except Exception as e:  # no silent failures
                st.update(state="failed", error=str(e), finished_at=time.time())
            finally:
                self._queue.task_done()

    def _trim(self) -> None:
        if len(self._status) > self._max_history:
            done = [k for k, v in self._status.items() if v["state"] in ("done", "failed")]
            for k in done[: len(self._status) - self._max_history]:
                self._status.pop(k, None)
