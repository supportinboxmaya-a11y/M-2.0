"""Secret manager.

One gate for every credential. Values are never logged; repr is masked.
Supports dual naming (NAME and NAME_API_KEY / NAME_KEY).
"""
import os


class SecretManager:
    def get(self, *names: str, required: bool = False) -> str:
        """Return the first non-empty env var among names ('' if absent)."""
        for n in names:
            v = os.environ.get(n, "")
            if v:
                return v
        if required:
            raise KeyError(f"Missing required secret (any of): {', '.join(names)}")
        return ""

    def has(self, *names: str) -> bool:
        return bool(self.get(*names))

    @staticmethod
    def mask(value: str) -> str:
        """Safe form for logs: keep first 4 chars only."""
        if not value:
            return "<empty>"
        return value[:4] + "…" + f"({len(value)} chars)"

    def __repr__(self) -> str:  # never leak contents
        return "<SecretManager (values hidden)>"


secrets = SecretManager()
