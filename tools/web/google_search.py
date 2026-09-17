
import os
import re
import requests
from typing import List, Dict

class GoogleSearch:
    def __init__(self):
        self.serpapi_key = os.environ.get("SERPAPI_KEY", "")
        self.google_key = os.environ.get("GOOGLE_API_KEY", "")
        self.cse_id = os.environ.get("GOOGLE_CSE_ID", "")

    def search(self, query: str, num_results: int = 5) -> str:
        results = []
        if self.serpapi_key:
            results = self._serpapi(query, num_results)
        elif self.google_key and self.cse_id:
            results = self._google_cse(query, num_results)
        if not results:
            results = self._ddg_html(query, num_results)
        if not results:
            results = self._ddg_api(query, num_results)
        if not results:
            return f"No results for: {query}"
        out = []
        for i, r in enumerate(results, 1):
            out.append(f"{i}. {r.get('title', '')}")
            if r.get("url"): out.append(f"   URL: {r['url']}")
            if r.get("snippet"): out.append(f"   {r['snippet'][:200]}")
            out.append("")
        return "\n".join(out).strip()

    def _serpapi(self, query, num):
        try:
            r = requests.get("https://serpapi.com/search",
                params={"q": query, "api_key": self.serpapi_key, "num": num}, timeout=10)
            return [{"title": i.get("title",""), "url": i.get("link",""), "snippet": i.get("snippet","")}
                    for i in r.json().get("organic_results", [])[:num]]
        except: return []

    def _google_cse(self, query, num):
        try:
            r = requests.get("https://www.googleapis.com/customsearch/v1",
                params={"q": query, "key": self.google_key, "cx": self.cse_id, "num": min(num,10)}, timeout=10)
            return [{"title": i.get("title",""), "url": i.get("link",""), "snippet": i.get("snippet","")}
                    for i in r.json().get("items", [])[:num]]
        except: return []

    def _ddg_html(self, query, num):
        try:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
            r = requests.get("https://html.duckduckgo.com/html/",
                params={"q": query}, headers=headers, timeout=10)
            titles = re.findall(r'class="result__a"[^>]*>([^<]+)<', r.text)
            urls = re.findall(r'class="result__url"[^>]*>([^<]+)<', r.text)
            snippets = re.findall(r'class="result__snippet"[^>]*>([^<]+)<', r.text)
            return [{"title": titles[i].strip() if i<len(titles) else "",
                     "url": urls[i].strip() if i<len(urls) else "",
                     "snippet": snippets[i].strip() if i<len(snippets) else ""}
                    for i in range(min(num, len(titles)))]
        except: return []

    def _ddg_api(self, query, num):
        try:
            r = requests.get("https://api.duckduckgo.com/",
                params={"q": query, "format": "json", "no_redirect": "1"}, timeout=10)
            data = r.json()
            results = []
            if data.get("AbstractText"):
                results.append({"title": data.get("Heading", query),
                                 "url": data.get("AbstractURL",""),
                                 "snippet": data.get("AbstractText","")[:300]})
            for item in data.get("RelatedTopics", [])[:num]:
                if isinstance(item, dict) and "Text" in item:
                    results.append({"title": item.get("Text","")[:80],
                                    "url": item.get("FirstURL",""),
                                    "snippet": item.get("Text","")})
            return results[:num]
        except: return []
