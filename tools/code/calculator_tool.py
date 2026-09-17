"""Maya 2.0 - Calculator Tool (Safe Math Evaluation)"""
import math
import re

# Only safe math functions/names allowed inside expressions
_ALLOWED_NAMES = {
    "abs": abs, "round": round, "min": min, "max": max, "sum": sum,
    "pow": pow, "sqrt": math.sqrt, "floor": math.floor, "ceil": math.ceil,
    "pi": math.pi, "e": math.e, "log": math.log, "log10": math.log10,
    "sin": math.sin, "cos": math.cos, "tan": math.tan,
}

_SAFE_PATTERN = re.compile(r"^[0-9a-zA-Z_+\-*/%.,() \t]+$")


class CalculatorTool:
    def run(self, expression: str = "", **kwargs) -> str:
        if not expression or not expression.strip():
            return "Error: expression required"

        expr = expression.strip()

        if not _SAFE_PATTERN.match(expr):
            return "Error: expression contains disallowed characters"

        try:
            result = eval(expr, {"__builtins__": {}}, _ALLOWED_NAMES)
            return str(result)
        except ZeroDivisionError:
            return "Error: division by zero"
        except Exception as e:
            return f"Error: could not evaluate expression ({e})"
