import json
import re
from typing import Any, Optional

def parse_json_response(text: str) -> Optional[Any]:
    try:
        clean = re.sub(r"```json|```", "", text).strip()
        return json.loads(clean)
    except:
        return None

def extract_steps(text: str) -> list:
    lines = text.split("\n")
    steps = []
    for line in lines:
        line = line.strip()
        if line and (line[0].isdigit() or line.startswith("-") or line.startswith("*")):
            steps.append(line.lstrip("0123456789.-* "))
    return steps
