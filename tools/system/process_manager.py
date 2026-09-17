from typing import List, Dict

try:
    import psutil
    _HAS_PSUTIL = True
except ImportError:
    _HAS_PSUTIL = False
    print("WARNING: psutil not available — ProcessManager will use stubs.")

class ProcessManager:
    def list_processes(self) -> List[Dict]:
        if not _HAS_PSUTIL:
            return [{"name": "(psutil unavailable)", "pid": 0, "status": "unknown"}]
        try:
            procs = []
            for p in psutil.process_iter(["pid", "name", "status"]):
                procs.append(p.info)
            return procs[:20]
        except:
            return []

    def kill_process(self, pid: int) -> dict:
        if not _HAS_PSUTIL:
            return {"success": False, "error": "psutil not installed on this platform"}
        try:
            p = psutil.Process(pid)
            p.terminate()
            return {"success": True, "pid": pid}
        except Exception as e:
            return {"success": False, "error": str(e)}
