"""
Maya 2.0 - GitHub Tool (read-only, via the public GitHub API)

Optional GITHUB_TOKEN env var raises the rate limit and allows access to
private repos the token has access to; without it, only public repos work,
at GitHub's lower unauthenticated rate limit.
"""
import os
import base64
import requests


class GitHubTool:
    BASE = "https://api.github.com"

    def _headers(self) -> dict:
        token = os.getenv("GITHUB_TOKEN")
        h = {"Accept": "application/vnd.github+json"}
        if token:
            h["Authorization"] = f"Bearer {token}"
        return h

    def get_repo(self, owner: str, repo: str, **kwargs) -> str:
        try:
            r = requests.get(f"{self.BASE}/repos/{owner}/{repo}", headers=self._headers(), timeout=15)
            if r.status_code != 200:
                return f"Error: GitHub API returned {r.status_code} — {r.text[:200]}"
            data = r.json()
            return (f"{data.get('full_name')}: {data.get('description') or '(no description)'}\n"
                    f"Stars: {data.get('stargazers_count')} | Forks: {data.get('forks_count')} | "
                    f"Language: {data.get('language')}")
        except requests.exceptions.RequestException as e:
            return f"Error: request failed ({e})"

    def list_files(self, owner: str, repo: str, path: str = "", **kwargs) -> str:
        try:
            r = requests.get(f"{self.BASE}/repos/{owner}/{repo}/contents/{path}",
                              headers=self._headers(), timeout=15)
            if r.status_code != 200:
                return f"Error: GitHub API returned {r.status_code} — {r.text[:200]}"
            items = r.json()
            if isinstance(items, dict):
                return items.get("name", "")
            return "\n".join(f"{i['type']}: {i['name']}" for i in items)
        except requests.exceptions.RequestException as e:
            return f"Error: request failed ({e})"

    def get_file(self, owner: str, repo: str, path: str, **kwargs) -> str:
        try:
            r = requests.get(f"{self.BASE}/repos/{owner}/{repo}/contents/{path}",
                              headers=self._headers(), timeout=15)
            if r.status_code != 200:
                return f"Error: GitHub API returned {r.status_code} — {r.text[:200]}"
            data = r.json()
            if data.get("encoding") == "base64":
                content = base64.b64decode(data["content"]).decode("utf-8", errors="replace")
                return content[:5000]
            return "Error: unsupported content encoding"
        except requests.exceptions.RequestException as e:
            return f"Error: request failed ({e})"
