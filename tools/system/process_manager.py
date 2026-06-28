import psutil
from typing import List, Dict

class ProcessManager:
    def list_processes(self) -> List[Dict]:
        try:
            procs = []
            for p in psutil.process_iter(["pid", "name", "status"]):
                procs.append(p.info)
            return procs[:20]
        except:
            return []

    def kill_process(self, pid: int) -> dict:
        try:
            p = psutil.Process(pid)
            p.terminate()
            return {"success": True, "pid": pid}
        except Exception as e:
            return {"success": False, "error": str(e)}
