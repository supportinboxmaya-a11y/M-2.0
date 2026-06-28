
import requests
from bs4 import BeautifulSoup

class WebScraper:
    def scrape(self, url: str, extract: str = "text") -> str:
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            }
            r = requests.get(url, headers=headers, timeout=15)
            if r.status_code == 403:
                return f"Access denied for {url}"
            if r.status_code != 200:
                return f"Error {r.status_code} for {url}"
            soup = BeautifulSoup(r.text, "html.parser")
            for tag in soup(["script", "style", "nav", "footer", "header"]):
                tag.decompose()
            lines = [l.strip() for l in soup.get_text(separator="\n").splitlines() if l.strip()]
            return "\n".join(lines)[:5000]
        except requests.Timeout:
            return f"Timeout fetching {url}"
        except Exception as e:
            return f"Scrape error: {str(e)}"

    def get_links(self, url: str) -> list:
        try:
            r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=10)
            soup = BeautifulSoup(r.text, "html.parser")
            return [a.get("href") for a in soup.find_all("a", href=True)][:20]
        except Exception:
            return []
