"""Maya 2.0 - REST API Tool (generic HTTP client for external APIs)"""
import requests


class RestApiTool:
    def request(self, url: str, method: str = "GET", headers: dict = None,
                body: dict = None, timeout: int = 15, **kwargs) -> str:
        if not url or not url.startswith(("http://", "https://")):
            return "Error: a valid http(s) URL is required"
        method = (method or "GET").upper()
        if method not in ("GET", "POST", "PUT", "PATCH", "DELETE"):
            return f"Error: unsupported method '{method}'"
        try:
            resp = requests.request(method, url, headers=headers or {}, json=body, timeout=timeout)
            preview = resp.text[:3000]
            return f"Status: {resp.status_code}\n{preview}"
        except requests.exceptions.Timeout:
            return "Error: request timed out"
        except requests.exceptions.ConnectionError:
            return "Error: could not connect to that URL"
        except requests.exceptions.RequestException as e:
            return f"Error: request failed ({e})"
