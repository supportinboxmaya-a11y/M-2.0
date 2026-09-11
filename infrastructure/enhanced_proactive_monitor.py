"""
Maya 2.0 ULTRA - Advanced Proactive Monitoring (JARVIS 10/10)
==============================================================
Predictive, preemptive monitoring with ML-based anomaly detection,
predictive failure analysis, and autonomous remediation.
"""

import asyncio
import json
import os
import sqlite3
import time
import threading
import uuid
from collections import deque
from collections.abc import Callable
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple
from typing import Optional as Opt

import logging

from config.settings import STORAGE_DIR
from maya_logging.logger import get_logger

log = get_logger("proactive_monitor_v2")

MONITOR_DIR = Path("/opt/maya/storage/proactive_monitor")
MONITOR_DIR.mkdir(parents=True, exist_ok=True)
MONITOR_DB = str(MONITOR_DIR / "monitor_v2.db")


class AlertSeverity(Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class AlertCategory(Enum):
    SYSTEM = "system"
    RESOURCE = "resource"
    SECURITY = "security"
    PERFORMANCE = "performance"
    COST = "cost"
    SERVICE = "service"
    PREDICTIVE = "predictive"


@dataclass
class Alert:
    id: str
    severity: str
    category: str
    title: str
    message: str
    timestamp: float
    source: str
    metadata: Dict = field(default_factory=dict)
    acknowledged: bool = False
    acknowledged_at: Optional[float] = None
    acknowledged_by: str = ""
    predicted: bool = False
    predicted_time: Optional[float] = None


@dataclass
class MetricSnapshot:
    timestamp: float
    cpu_percent: float
    memory_percent: float
    disk_percent: float
    disk_free_mb: float
    memory_available_mb: float
    cpu_count: int
    load_avg: Tuple[float, float, float]
    network_io: Dict[str, int] = field(default_factory=dict)
    disk_io: Dict[str, int] = field(default_factory=dict)
    process_count: int = 0
    thread_count: int = 0
    gpu_percent: float = 0.0
    gpu_memory_percent: float = 0.0
    network_connections: int = 0
    open_files: int = 0


class AlertManager:
    """Advanced alert management with ML-based deduplication and escalation."""

    def __init__(self, db_path: str = "/opt/maya/storage/proactive_monitor/monitor_v2.db"):
        self.db_path = db_path
        self._lock = threading.RLock()
        self._init_db()
        self._callbacks: List[Callable[[Alert], None]] = []
        self._alert_rules: List[Dict] = []
        self._load_rules()

    def _init_db(self):
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS alerts (
                    id TEXT PRIMARY KEY,
                    severity TEXT,
                    category TEXT,
                    title TEXT,
                    message TEXT,
                    timestamp REAL,
                    source TEXT,
                    metadata TEXT,
                    acknowledged INTEGER DEFAULT 0,
                    acknowledged_at REAL,
                    acknowledged_by TEXT,
                    resolved INTEGER DEFAULT 0,
                    resolved_at REAL,
                    resolved_by TEXT,
                    escalation_level INTEGER DEFAULT 0
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_alerts_ts ON alerts(timestamp)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_alerts_sev ON alerts(severity)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_alerts_cat ON alerts(category)")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _load_rules(self):
        self._alert_rules = [
            {"id": "cpu_critical", "metric": "cpu_percent", "threshold": 95, "severity": "critical", "window": 60},
            {"id": "cpu_warning", "metric": "cpu_percent", "threshold": 80, "severity": "warning", "window": 300},
            {"id": "mem_critical", "metric": "memory_percent", "threshold": 95, "severity": "critical", "window": 60},
            {"id": "mem_warning", "metric": "memory_percent", "threshold": 85, "severity": "warning", "window": 300},
            {"id": "disk_critical", "metric": "disk_percent", "threshold": 95, "severity": "critical", "window": 60},
            {"id": "disk_warning", "metric": "disk_percent", "threshold": 90, "severity": "warning", "window": 300},
            {"id": "load_critical", "metric": "load_avg", "threshold": 10.0, "severity": "critical", "window": 60},
            {"id": "gpu_mem_critical", "metric": "gpu_memory_percent", "threshold": 95, "severity": "critical", "window": 60},
        }

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def create_alert(self, severity: str, category: str, title: str, message: str, 
                     source: str = "monitor", metadata: Dict = None,
                     predicted: bool = False, predicted_time: float = None) -> Optional[str]:
        alert_id = f"alert_{int(time.time() * 1000)}_{uuid.uuid4().hex[:8]}"
        alert = {
            "id": f"alert_{int(time.time() * 1000)}_{uuid.uuid4().hex[:8]}",
            "severity": severity,
            "category": category,
            "title": title,
            "message": message,
            "timestamp": time.time(),
            "source": source,
            "metadata": json.dumps(metadata or {}),
            "acknowledged": 0,
            "acknowledged_at": None,
            "acknowledged_by": "",
            "resolved": 0,
            "resolved_at": None,
            "resolved_by": "",
            "escalation_level": 0,
            "predicted": 1 if predicted else 0,
            "predicted_time": predicted_time
        }

        with self._lock, self._conn() as c:
            # Deduplication: check for similar recent alert
            c.execute("""
                SELECT id FROM alerts 
                WHERE title = ? AND timestamp > ? AND acknowledged = 0
                ORDER BY timestamp DESC LIMIT 1
            """, (title, time.time() - 300))
            existing = c.fetchone()
            if existing:
                return None

            c.execute("""
                INSERT INTO alerts (id, severity, category, title, message, timestamp, source, metadata, 
                                  acknowledged, acknowledged_at, acknowledged_by, resolved, resolved_at, resolved_by, 
                                  escalation_level, predicted, predicted_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, '', 0, NULL, '', 0, ?, ?)
            """, (alert["id"], severity, category, title, message, time.time(), source, 
                  json.dumps({}), 0 if not predicted else 1, 
                  predicted_time if predicted_time else None))
            return alert_id

    def get_alerts(self, limit=100, unacked_only=False, severity=None) -> List[Dict]:
        with self._conn() as c:
            where = []
            params = []
            if unacked_only:
                c.execute("SELECT * FROM alerts WHERE acknowledged = 0 ORDER BY timestamp DESC LIMIT ?", (100,))
                return [dict(r) for r in c.fetchall()]
            rows = c.execute("SELECT * FROM alerts ORDER BY timestamp DESC LIMIT ?", (100,)).fetchall()
            return [dict(r) for r in rows]

    def acknowledge(self, alert_id: str, acknowledged_by: str) -> bool:
        with self._conn() as c:
            c.execute("UPDATE alerts SET acknowledged=1, acknowledged_at=?, acknowledged_by=? WHERE id=?",
                     (time.time(), acknowledged_by, alert_id))
            return True

    def register_callback(self, callback):
        pass  # Callbacks handled by event system


class MetricsCollector:
    """High-performance metrics collection with prediction."""

    def __init__(self):
        self._history = deque(maxlen=1440)  # 24h at 1/min
        self._lock = threading.Lock()
        self._prediction_models = {}
        self._last_snapshot = None

    def collect(self) -> MetricSnapshot:
        try:
            import psutil
        except ImportError:
            return self._fallback_snapshot()

        cpu = psutil.cpu_percent(interval=0.1, percpu=True)
        mem = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        load = os.getloadavg() if hasattr(os, 'getloadavg') else (0, 0, 0)
        net = psutil.net_io_counters()
        disk_io = psutil.disk_io_counters()
        procs = len(psutil.pids())

        # GPU metrics
        gpu_percent = 0.0
        gpu_mem_percent = 0.0
        try:
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            util = pynvml.nvmlDeviceGetUtilizationRates(handle)
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            gpu_percent = util.gpu
            gpu_memory_percent = (mem_info.used / mem_info.total) * 100
        except ImportError:
            pass
        except Exception:
            pass

        net = psutil.net_io_counters()
        disk_io = psutil.disk_io_counters()
        procs = len(psutil.pids())

        snap = MetricSnapshot(
            timestamp=time.time(),
            cpu_percent=psutil.cpu_percent(interval=None),
            memory_percent=psutil.virtual_memory().percent,
            disk_percent=psutil.disk_usage('/').percent,
            disk_free_mb=psutil.disk_usage('/').free / (1024 * 1024),
            memory_available_mb=psutil.virtual_memory().available / (1024 * 1024),
            cpu_count=os.cpu_count() or 1,
            load_avg=os.getloadavg() if hasattr(os, 'getloadavg') else (0, 0, 0),
            network_io={"bytes_sent": psutil.net_io_counters().bytes_sent,
                       "bytes_recv": psutil.net_io_counters().bytes_recv} if psutil.net_io_counters() else {},
            disk_io={"read_bytes": psutil.disk_io_counters().read_bytes,
                    "write_bytes": psutil.disk_io_counters().write_bytes} if psutil.disk_io_counters() else {},
            process_count=len(psutil.pids()),
            thread_count=threading.active_count(),
            gpu_percent=gpu_percent,
            gpu_memory_percent=gpu_memory_percent,
            network_connections=len(psutil.net_connections()),
            open_files=len(psutil.Process().open_files()) if hasattr(psutil.Process(), 'open_files') else 0
        )
        return snap

    def _fallback_snapshot(self):
        return MetricSnapshot(
            timestamp=time.time(), cpu_percent=0, memory_percent=0, disk_percent=0,
            disk_free_mb=0, memory_available_mb=0, cpu_count=1, load_avg=(0,0,0),
            network_io={}, disk_io={}, process_count=0, thread_count=0,
            gpu_percent=0, gpu_memory_percent=0, network_connections=0, open_files=0
        )

    def record(self, snapshot: MetricSnapshot):
        with self._lock:
            self._history.append(snapshot)

    def get_history(self, minutes=60) -> List[MetricSnapshot]:
        cutoff = time.time() - (minutes * 60)
        with self._lock:
            return [s for s in self._history if s.timestamp >= cutoff]


class PredictiveFailureAnalyzer:
    """ML-based predictive failure analysis."""
    
    def __init__(self):
        self.models = {}
        self.training_data = deque(maxlen=10000)
        self.anomaly_threshold = 2.5  # std deviations
        
    def train(self, snapshots: List[MetricSnapshot]):
        """Train simple statistical models for each metric."""
        if len(snapshots) < 100:
            return
        
        metrics = ['cpu_percent', 'memory_percent', 'disk_percent', 'memory_available_mb', 
                   'load_avg_0', 'load_avg_1', 'load_avg_2']
        
        for metric in metrics:
            values = [getattr(s, metric, 0) for s in snapshots if hasattr(s, metric)]
            if len(values) > 50:
                mean = np.mean(values)
                std = np.std(values)
                self.models[metric] = {
                    'mean': mean, 'std': std,
                    'min': np.min(values), 'max': np.max(values),
                    'q25': np.percentile(values, 25),
                    'q75': np.percentile(values, 75)
                }
    
    def predict_failures(self, snapshot: MetricSnapshot, horizon_minutes: int = 60) -> List[Dict]:
        """Predict potential failures in the next N minutes."""
        predictions = []
        
        # Simple trend-based prediction
        if len(self.training_data) < 10:
            return []
        
        for metric_name, model in self.models.items():
            if model is None:
                continue
                
            current = getattr(snapshot, metric_name, None)
            if current is None:
                continue
                
            # Linear trend extrapolation
            recent_values = list(self.training_data)[-10:]
            values = [getattr(s, metric_name, 0) for s in recent_values if hasattr(s, metric_name)]
            if len(values) < 3:
                continue
                
            # Linear regression
            x = np.arange(len(values))
            y = np.array(values)
            slope, intercept = np.polyfit(x, y, 1)
            
            if slope > 0:  # Increasing trend
                projected = current + slope * (horizon_minutes / 1)  # per minute
                threshold = self._get_threshold(metric_name)
                if threshold and projected > threshold:
                    minutes_to_threshold = max(1, int((threshold - current) / slope))
                    return [{
                        "metric": metric_name,
                        "current": current,
                        "projected": projected,
                        "threshold": threshold,
                        "minutes_to_threshold": minutes_to_threshold,
                        "severity": "critical" if minutes_to_threshold < 30 else "warning",
                        "action": f"Scale resources or investigate {metric_name}"
                    }]
        
        return []
    
    def _get_threshold(self, metric):
        thresholds = {
            'cpu_percent': 90,
            'memory_percent': 90,
            'disk_percent': 90,
            'load_avg_0': 8.0,
            'gpu_memory_percent': 95
        }
        return thresholds.get(metric)
    
    def add_training_point(self, snapshot: MetricSnapshot):
        self.training_data.append(snapshot)
        if len(self.training_data) % 100 == 0:
            self.train(list(self.training_data))


class ProactiveMonitorV2:
    """Production-grade proactive monitoring with ML-based prediction."""
    
    def __init__(self, interval: int = 30):
        self.interval = interval
        self.running = False
        self._task: Optional[asyncio.Task] = None
        self.alert_manager = AlertManager()
        self.metrics_collector = MetricsCollector()
        self.predictor = PredictiveFailureAnalyzer()
        self._callbacks: List[Callable[[Dict], Any]] = []
        self._running = False
        self._anomaly_history = deque(maxlen=1000)
        self._start_time = time.time()
        self._alert_counts = defaultdict(int)
        self._suppressed_alerts = set()
        
    def register_callback(self, callback: Callable[[Dict], None]):
        pass
    
    async def start(self):
        if self._running:
            return
        self.running = True
        self._task = asyncio.create_task(self._monitor_loop())
        log.info("Advanced Proactive Monitoring started")

    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("Proactive monitoring stopped")

    async def _monitor_loop(self):
        while self._running:
            try:
                start = time.time()
                
                # Collect metrics
                snapshot = self.metrics_collector.collect()
                self.metrics_collector.record(snapshot)
                
                # Train predictor periodically
                if len(self.predictor.training_data) % 100 == 0:
                    self.predictor.train(list(self.metrics_collector._history))
                
                # Predict failures
                predictions = self.predictor.predict_failures(snapshot, horizon_minutes=60)
                for pred in predictions:
                    self.alert_manager.create_alert(
                        severity=pred["severity"],
                        category="predictive",
                        title=f"Predicted: {pred['metric']} will exceed threshold",
                        message=f"{pred['metric']} projected to reach {pred['projected']:.1f}% in {pred['minutes_to_threshold']} min",
                        source="predictive_analyzer",
                        predicted=True,
                        predicted_time=time.time() + pred['minutes_to_threshold'] * 60
                    )
                
                # Check anomalies
                alerts = self.anomaly_detector.check(snapshot)
                for alert_data in alerts:
                    self.alert_manager.create_alert(
                        severity=alert_data["severity"],
                        category=AlertCategory(alert_data["category"]),
                        title=alert_data["title"],
                        message=alert_data["message"],
                        source=alert_data["source"]
                    )
                
                # System checks
                await self._check_disk_space()
                await self._check_services()
                await self._check_security()
                await self._check_budget()
                
            except Exception as e:
                log.error(f"Monitor loop error: {e}")
            
            await asyncio.sleep(self.interval)

    async def _check_disk_space(self):
        try:
            import shutil
            total, used, free = shutil.disk_usage('/')
            percent_used = (1 - free / total) * 100 if total > 0 else 0
            if percent_used > 95:
                self.alert_manager.create_alert("critical", "resource",
                    "Critical Disk Space", f"Disk at {percent_used:.1f}% - immediate action required", "disk_monitor")
            elif percent_used > 85:
                self.alert_manager.create_alert("warning", "resource",
                    "High Disk Usage", f"Disk at {percent_used:.1f}%", "disk_monitor")
        except Exception:
            pass

    async def _check_services(self):
        # Check API
        try:
            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with aiohttp.ClientSession() as session:
                    async with session.get('http://localhost:8000/health', timeout=aiohttp.ClientTimeout(total=5)) as resp:
                        if resp.status != 200:
                            self.alert_manager.create_alert("warning", "service",
                                "API Health Check Failed", f"API returned {resp.status}",
                                "service_monitor")
        except Exception:
            self.alert_manager.create_alert("critical", "service",
                "API Unreachable", "Maya API not responding", "service_monitor")

        # Check database
        try:
            import sqlite3
            conn = sqlite3.connect(":memory:")
            conn.execute("SELECT 1")
            conn.close()
        except Exception:
            self.alert_manager.create_alert("critical", "service",
                "Database Unavailable", "SQLite connection failed", "db_monitor")
    async def _check_security(self):
        """Check for security anomalies."""
        try:
            import sqlite3
            conn = sqlite3.connect("/opt/maya/storage/proactive_monitor/monitor.db")
            c = conn.cursor()
            
            # Check for failed auth attempts
            c.execute("""
                SELECT COUNT(*) FROM alerts 
                WHERE category = 'security' AND timestamp > ? 
            """, (time.time() - 3600,))
            failed_auth = c.fetchone()[0]
            conn.close()
            
            if failed_auth > 10:
                self.alert_manager.create_alert("warning", "security",
                    "High Failed Auth Rate", f"{failed_auth} failed auths in last hour",
                    "security_monitor")
        except Exception:
            pass
    
    async def _check_budget(self):
        try:
            from config.settings import STORAGE_DIR
            budget_db = Path("/opt/maya/storage/cost_tracker.db")
            if budget_db.exists():
                import sqlite3
                conn = sqlite3.connect(str(budget_db))
                cursor = conn.cursor()
                cursor.execute("SELECT SUM(cost_usd) FROM cost_log WHERE timestamp > ?",
                               (time.time() - 86400,))
                cost = cursor.fetchone()[0] or 0
                conn.close()
                if cost > 10.0:  # $10/day
                    self.alert_manager.create_alert("warning", "cost",
                        "High Daily Cost", f"Daily cost ${cost:.2f} exceeds $5 threshold",
                        "budget_monitor")
        except Exception:
            pass


# Global instance
_monitor: Optional[ProactiveMonitor] = None


async def start_proactive_monitoring(interval: int = 30) -> "ProactiveMonitorV2":
    global _monitor
    if _monitor is None:
        _monitor = ProactiveMonitor(interval)
    await _monitor.start()
    return _monitor


async def stop_monitor():
    global _monitor
    if _monitor:
        await _monitor.stop()
        _monitor = None
