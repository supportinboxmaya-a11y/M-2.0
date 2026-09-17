"""
Code execution sandbox for Maya-Learner.
Wraps existing SandboxExecutor with learner-specific execution logic.
"""
import json
import uuid
import asyncio
import tempfile
import os
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, field
from datetime import datetime

from infrastructure.sandbox_executor import SandboxExecutor, SandboxConfig, ExecutionResult as SandboxExecutionResult
from agents.learner.config import LearnerConfig


@dataclass
class ExecutionResult:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    code: str = ""
    success: bool = False
    output: str = ""
    error: Optional[str] = None
    execution_time: float = 0.0
    timestamp: datetime = field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = field(default_factory=dict)


class CodeExecutor:
    """Handles safe execution of synthesized code in sandbox."""

    def __init__(self, config: Optional[LearnerConfig] = None):
        self.config = config or LearnerConfig
        self.sandbox = SandboxExecutor()

    def _build_test_harness(self, code: str, test_inputs: Optional[List[Dict]] = None) -> str:
        """Wrap synthesized code in a test harness that captures output."""
        test_inputs = test_inputs or [{}]

        harness = f"""
{code}

# ========== TEST HARNESS ==========
import json
import sys
import traceback
from typing import Any, Dict

def _run_tests() -> Dict[str, Any]:
    results = {{}}
    try:
        # Try to find a main function or callable
        main_func = None
        for name in ['main', 'run', 'execute', 'solve']:
            if name in globals() and callable(globals()[name]):
                main_func = globals()[name]
                break

        if main_func:
            # Try calling with test inputs
            for i, test_input in enumerate({json.dumps(test_inputs)}):
                try:
                    if isinstance(test_input, dict) and test_input:
                        result = main_func(**test_input)
                    else:
                        result = main_func()
                    results[f"test_{{i}}"] = {{
                        "success": True,
                        "result": result
                    }}
                except TypeError:
                    # Function might not accept kwargs
                    try:
                        result = main_func(test_input)
                        results[f"test_{{i}}"] = {{
                            "success": True,
                            "result": result
                        }}
                    except Exception as e:
                        results[f"test_{{i}}"] = {{
                            "success": False,
                            "error": str(e)
                        }}
                except Exception as e:
                    results[f"test_{{i}}"] = {{
                        "success": False,
                        "error": str(e)
                    }}
        else:
            # No main function found - check for class-based solution
            for name, obj in globals().items():
                if isinstance(obj, type) and name not in ['__builtins__', '__name__', '__file__']:
                    try:
                        instance = obj()
                        if hasattr(instance, 'run') or hasattr(instance, 'execute'):
                            method = getattr(instance, 'run', getattr(instance, 'execute', None))
                            if method and callable(method):
                                result = method()
                                results["class_test"] = {{
                                    "success": True,
                                    "result": result,
                                    "class": name
                                }}
                                break
                    except:
                        pass
            if not results:
                results["no_entry"] = {{"success": True, "result": "No entry point found", "warning": "Code loaded but no executable function found"}}

    except Exception as e:
        results["harness_error"] = {{
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc()
        }}

    return results

if __name__ == "__main__":
    test_results = _run_tests()
    print(json.dumps(test_results, default=str))
"""
        return harness

    async def execute(
        self,
        code: str,
        test_inputs: Optional[List[Dict]] = None,
        timeout: Optional[int] = None,
    ) -> ExecutionResult:
        """Execute code in sandbox and return structured result."""
        timeout = timeout or self.config.SANDBOX_TIMEOUT
        start_time = asyncio.get_event_loop().time()

        harness_code = self._build_test_harness(code, test_inputs)

        # Create sandbox config with timeout
        sandbox_config = SandboxConfig(
            runtime="native",  # Use native since gVisor/Firecracker not available
            language="python",
            timeout_seconds=timeout,
            memory_limit_mb=512,
            cpu_limit_percent=50,
            network_enabled=False,
            filesystem_read_only=True,
        )

        try:
            result: SandboxExecutionResult = await self.sandbox.execute(harness_code, config=sandbox_config)

            execution_time = asyncio.get_event_loop().time() - start_time

            # Parse sandbox output
            output = result.stdout if isinstance(result, SandboxExecutionResult) else str(result)
            error = result.stderr if isinstance(result, SandboxExecutionResult) else ""

            # Try to parse JSON from stdout
            parsed_output = {}
            success = result.success if isinstance(result, SandboxExecutionResult) else True

            try:
                # Find the last valid JSON line
                for line in reversed(output.strip().split('\n')):
                    line = line.strip()
                    if line.startswith('{') and line.endswith('}'):
                        parsed_output = json.loads(line)
                        break
            except json.JSONDecodeError:
                pass

            if not parsed_output and error:
                success = False

            return ExecutionResult(
                code=code,
                success=success,
                output=json.dumps(parsed_output) if parsed_output else output,
                error=error if error else None,
                execution_time=execution_time,
                metadata={"raw_output": output, "raw_error": error},
            )

        except asyncio.TimeoutError:
            return ExecutionResult(
                code=code,
                success=False,
                output="",
                error=f"Execution timeout ({timeout}s)",
                execution_time=timeout,
            )
        except Exception as e:
            return ExecutionResult(
                code=code,
                success=False,
                output="",
                error=str(e),
                execution_time=asyncio.get_event_loop().time() - start_time,
            )

    async def validate_syntax(self, code: str) -> Dict[str, Any]:
        """Quick syntax validation without execution."""
        try:
            compile(code, '<string>', 'exec')
            return {"valid": True, "error": None}
        except SyntaxError as e:
            return {"valid": False, "error": f"Syntax error: {e.msg} at line {e.lineno}"}
        except Exception as e:
            return {"valid": False, "error": str(e)}