"""Maya 2.0 - GraphQL Tool (generic client for GraphQL APIs)

Same conventions as RestApiTool: string results, defensive validation,
short timeouts, previews capped so tool output stays LLM-friendly.
"""
import json


class GraphQLTool:
    def query(self, url: str, query: str, variables: dict = None,
              headers: dict = None, timeout: int = 15, **kwargs) -> str:
        if not url or not url.startswith(("http://", "https://")):
            return "Error: a valid http(s) URL is required"
        query = (query or "").strip()
        if not query:
            return "Error: a GraphQL query string is required"
        if isinstance(variables, str):
            try:
                variables = json.loads(variables) if variables.strip() else None
            except json.JSONDecodeError:
                return "Error: variables must be a JSON object"
        try:
            import requests
            resp = requests.post(
                url,
                json={"query": query, "variables": variables or {}},
                headers={"Content-Type": "application/json", **(headers or {})},
                timeout=timeout)
        except Exception as e:
            name = type(e).__name__
            if "Timeout" in name:
                return "Error: request timed out"
            if "Connection" in name:
                return "Error: could not connect to that URL"
            return f"Error: request failed ({e})"

        try:
            payload = resp.json()
        except ValueError:
            return (f"Status: {resp.status_code}\n"
                    f"Error: response was not JSON\n{resp.text[:500]}")

        if payload.get("errors"):
            msgs = "; ".join(str(e.get("message", e))
                             for e in payload["errors"][:5])
            return f"Status: {resp.status_code}\nGraphQL errors: {msgs[:1500]}"

        data = json.dumps(payload.get("data", {}), ensure_ascii=False,
                          indent=2, default=str)
        return f"Status: {resp.status_code}\n{data[:3000]}"
