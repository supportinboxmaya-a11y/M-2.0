
import os, requests, re
from typing import List

class YouTubeTool:
    def __init__(self):
        self.api_key = os.environ.get("GOOGLE_API_KEY", "")

    def search(self, query: str, max_results: int = 5) -> str:
        try:
            headers = {"User-Agent": "Mozilla/5.0"}
            r = requests.get("https://www.youtube.com/results",
                params={"search_query": query}, headers=headers, timeout=10)
            video_ids = re.findall(r'"videoId":"([a-zA-Z0-9_-]{11})"', r.text)
            titles = re.findall(r'"title":{"runs":\[{"text":"([^"]+)"', r.text)
            results = []
            seen = set()
            for i, vid_id in enumerate(video_ids):
                if vid_id not in seen and len(results) < max_results:
                    seen.add(vid_id)
                    title = titles[i] if i < len(titles) else "Unknown"
                    results.append(f"• {title}\n  URL: https://youtube.com/watch?v={vid_id}")
            return "\n\n".join(results) if results else "No results"
        except Exception as e:
            return f"Error: {e}"

    def get_transcript(self, url: str) -> str:
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            vid_id = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
            if not vid_id:
                return "Invalid URL"
            t = YouTubeTranscriptApi.get_transcript(vid_id.group(1))
            return " ".join([x["text"] for x in t])[:5000]
        except ImportError:
            return "Run: pip install youtube-transcript-api"
        except Exception as e:
            return f"Error: {e}"
