from typing import Dict, List

def format_plan(plan: Dict) -> str:
    lines = [f"🧠 Reasoning: {plan.get('reasoning', '')}"]
    for s in plan.get("steps", []):
        lines.append(f"  {s.get('step', '')}. {s.get('description', '')}")
        if s.get("tool"):
            lines.append(f"     🔧 Tool: {s['tool']}")
    return "\n".join(lines)

def format_result(result: Dict) -> str:
    if result.get("success"):
        return f"✅ {result.get('result', '')[:300]}"
    return f"❌ Error: {result.get('error', 'Unknown error')}"
