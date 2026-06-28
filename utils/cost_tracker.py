"""
Maya 2.0 - Cost & Token Tracker
---------------------------------
Track LLM token usage and estimated costs.
"""

from typing import Dict, List, Optional
from datetime import datetime
from maya_logging.logger import get_logger

log = get_logger("cost")

# Pricing per 1M tokens (input/output) in USD
PRICING = {
    "groq": {
        "llama3-8b-8192":     {"input": 0.05,  "output": 0.10},
        "llama3-70b-8192":    {"input": 0.59,  "output": 0.79},
        "mixtral-8x7b-32768": {"input": 0.24,  "output": 0.24},
    },
    "gemini": {
        "gemini-1.5-flash":   {"input": 0.075, "output": 0.30},
        "gemini-1.5-pro":     {"input": 3.50,  "output": 10.50},
    },
    "openai": {
        "gpt-4o-mini":        {"input": 0.15,  "output": 0.60},
        "gpt-4o":             {"input": 5.00,  "output": 15.00},
        "gpt-3.5-turbo":      {"input": 0.50,  "output": 1.50},
    },
    "claude": {
        "claude-3-haiku-20240307":  {"input": 0.25,  "output": 1.25},
        "claude-3-sonnet-20240229": {"input": 3.00,  "output": 15.00},
        "claude-3-opus-20240229":   {"input": 15.00, "output": 75.00},
    },
    "deepseek": {
        "deepseek-chat":      {"input": 0.27,  "output": 1.10},
        "deepseek-coder":     {"input": 0.27,  "output": 1.10},
    },
}


class CostTracker:
    """
    Token usage এবং cost track করে।
    - প্রতিটা LLM call এর tokens count করে
    - Cost estimate করে
    - Session summary দেয়
    - Budget alert দেয়
    """

    def __init__(self, budget_usd: float = 1.0):
        self.budget_usd = budget_usd
        self.session_start = datetime.now().isoformat()
        self.records: List[Dict] = []
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.total_cost_usd = 0.0

    def track(self, provider: str, model: str, input_tokens: int, output_tokens: int) -> Dict:
        """
        LLM call track করে এবং cost calculate করে।
        """
        cost = self._calculate_cost(provider, model, input_tokens, output_tokens)

        record = {
            "timestamp": datetime.now().isoformat(),
            "provider": provider,
            "model": model,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens,
            "cost_usd": cost
        }

        self.records.append(record)
        self.total_input_tokens += input_tokens
        self.total_output_tokens += output_tokens
        self.total_cost_usd += cost

        # Budget alert
        if self.total_cost_usd >= self.budget_usd * 0.8:
            log.warning(f"Budget alert! Used ${self.total_cost_usd:.4f} of ${self.budget_usd:.2f}")

        log.debug(f"Tokens: {input_tokens}+{output_tokens} | Cost: ${cost:.6f} | Total: ${self.total_cost_usd:.4f}")
        return record

    def estimate_cost(self, provider: str, model: str, text: str) -> float:
        """Text এর estimated cost।"""
        estimated_tokens = len(text) // 4
        return self._calculate_cost(provider, model, estimated_tokens, estimated_tokens // 2)

    def get_summary(self) -> Dict:
        """Session cost summary।"""
        by_provider: Dict[str, Dict] = {}
        for r in self.records:
            p = r["provider"]
            if p not in by_provider:
                by_provider[p] = {"calls": 0, "tokens": 0, "cost": 0.0}
            by_provider[p]["calls"] += 1
            by_provider[p]["tokens"] += r["total_tokens"]
            by_provider[p]["cost"] += r["cost_usd"]

        return {
            "session_start": self.session_start,
            "total_calls": len(self.records),
            "total_input_tokens": self.total_input_tokens,
            "total_output_tokens": self.total_output_tokens,
            "total_tokens": self.total_input_tokens + self.total_output_tokens,
            "total_cost_usd": round(self.total_cost_usd, 6),
            "budget_usd": self.budget_usd,
            "budget_used_pct": round(self.total_cost_usd / self.budget_usd * 100, 1) if self.budget_usd else 0,
            "by_provider": by_provider,
            "cheapest_provider": self._cheapest_provider(),
        }

    def print_summary(self):
        """Cost summary print করে।"""
        s = self.get_summary()
        print(f"\n{'='*40}")
        print(f"Maya Cost Summary")
        print(f"{'='*40}")
        print(f"Total calls:  {s['total_calls']}")
        print(f"Total tokens: {s['total_tokens']:,}")
        print(f"Total cost:   ${s['total_cost_usd']:.6f}")
        print(f"Budget used:  {s['budget_used_pct']}%")
        print(f"\nBy provider:")
        for provider, data in s['by_provider'].items():
            print(f"  {provider}: {data['calls']} calls, {data['tokens']:,} tokens, ${data['cost']:.6f}")
        print('='*40)

    def is_over_budget(self) -> bool:
        return self.total_cost_usd >= self.budget_usd

    def reset(self):
        self.records = []
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.total_cost_usd = 0.0

    def _calculate_cost(self, provider: str, model: str, input_tokens: int, output_tokens: int) -> float:
        pricing = PRICING.get(provider, {}).get(model)
        if not pricing:
            # Default estimate if model not in pricing
            return (input_tokens + output_tokens) * 0.000001
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost

    def _cheapest_provider(self) -> Optional[str]:
        if not self.records:
            return None
        by_provider = {}
        for r in self.records:
            p = r["provider"]
            tokens = r.get("total_tokens", 1)
            cost = r.get("cost_usd", 0)
            if p not in by_provider:
                by_provider[p] = []
            if tokens > 0:
                by_provider[p].append(cost / tokens)
        if not by_provider:
            return None
        return min(by_provider, key=lambda p: sum(by_provider[p]) / len(by_provider[p]))
