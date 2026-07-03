"""Shared thread-safe SQLite helper for the enterprise package."""
import pathlib
import sqlite3
import threading


class DB:
    def __init__(self, path: str = "storage/enterprise.db"):
        pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self.lock = threading.Lock()

    def execute(self, sql: str, params: tuple = ()):
        with self.lock:
            cur = self.conn.execute(sql, params)
            self.conn.commit()
            return cur

    def query(self, sql: str, params: tuple = ()) -> list:
        with self.lock:
            return [dict(r) for r in self.conn.execute(sql, params).fetchall()]
