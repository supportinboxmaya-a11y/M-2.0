import json
import re
from typing import Any

def safe_json(text: str) -> Any:
    try:
        clean = text.strip().strip("```json").strip("```").strip()
        return json.loads(clean)
    except:
        return None

def truncate(text: str, max_len: int = 500) -> str:
    return text[:max_len] + "..." if len(text) > max_len else text

def extract_code(text: str, lang: str = "python") -> str:
    pattern = rf"```{lang}(.*?)```"
    matches = re.findall(pattern, text, re.DOTALL)
    return matches[0].strip() if matches else text
