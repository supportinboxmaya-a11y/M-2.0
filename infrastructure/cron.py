"""
Maya 2.0 - Cron Expression Parser
---------------------------------
Parses standard 5-field cron expressions and tests whether a given
datetime matches. Stdlib-only, no croniter dependency.

Fields (in order):   minute hour day-of-month month day-of-week
    minute        0-59
    hour          0-23
    day-of-month  1-31
    month         1-12
    day-of-week   0-6   (0 = Sunday)

Each field supports:
    *            any value
    5            a single value
    1,3,5        a list
    1-5          a range
    */15         a step over the whole range
    1-10/2       a step over a range

Convenience aliases: @hourly @daily @weekly @monthly @yearly.

Day-of-month and day-of-week use cron's traditional OR semantics: when
both are restricted (neither is '*'), a time matches if EITHER field
matches, which is what users expect from real cron.
"""

from datetime import datetime, timedelta
from typing import List, Set

_ALIASES = {
    "@hourly": "0 * * * *",
    "@daily": "0 0 * * *",
    "@midnight": "0 0 * * *",
    "@weekly": "0 0 * * 0",
    "@monthly": "0 0 1 * *",
    "@yearly": "0 0 1 1 *",
    "@annually": "0 0 1 1 *",
}

_BOUNDS = [(0, 59), (0, 23), (1, 31), (1, 12), (0, 6)]


class CronExpression:
    """A parsed 5-field cron expression."""

    def __init__(self, expr: str):
        self.raw = (expr or "").strip()
        norm = _ALIASES.get(self.raw.lower(), self.raw)
        parts = norm.split()
        if len(parts) != 5:
            raise ValueError(
                f"cron expression must have 5 fields (got {len(parts)}): '{expr}'")
        self.fields: List[Set[int]] = [
            self._parse_field(parts[i], *_BOUNDS[i]) for i in range(5)
        ]
        self._dom_restricted = parts[2] != "*"
        self._dow_restricted = parts[4] != "*"

    # ── parsing ───────────────────────────────────────────────────
    @staticmethod
    def _parse_field(field: str, lo: int, hi: int) -> Set[int]:
        values: Set[int] = set()
        for token in field.split(","):
            token = token.strip()
            step = 1
            if "/" in token:
                base, step_s = token.split("/", 1)
                if not step_s.isdigit() or int(step_s) == 0:
                    raise ValueError(f"invalid step in cron field: '{token}'")
                step = int(step_s)
            else:
                base = token

            if base == "*":
                start, end = lo, hi
            elif "-" in base:
                a, b = base.split("-", 1)
                start, end = int(a), int(b)
            else:
                start = end = int(base)

            if start < lo or end > hi or start > end:
                raise ValueError(
                    f"cron field value out of range [{lo}-{hi}]: '{token}'")
            values.update(range(start, end + 1, step))
        if not values:
            raise ValueError(f"empty cron field: '{field}'")
        return values

    # ── matching ──────────────────────────────────────────────────
    def matches(self, dt: datetime) -> bool:
        minute, hour, dom, month, dow = self.fields
        # cron dow: 0 = Sunday; Python weekday(): 0 = Monday
        py_dow = (dt.weekday() + 1) % 7
        if dt.minute not in minute or dt.hour not in hour or dt.month not in month:
            return False
        dom_ok = dt.day in dom
        dow_ok = py_dow in dow
        if self._dom_restricted and self._dow_restricted:
            return dom_ok or dow_ok        # cron OR semantics
        return dom_ok and dow_ok

    def next_after(self, dt: datetime, horizon_minutes: int = 366 * 24 * 60):
        """Return the next datetime strictly after `dt` that matches, or
        None if none within the horizon (safety cap ~1 year)."""
        cur = dt.replace(second=0, microsecond=0) + timedelta(minutes=1)
        for _ in range(horizon_minutes):
            if self.matches(cur):
                return cur
            cur += timedelta(minutes=1)
        return None
