"""
Maya 2.0 — Tool Synthesizer (Phase 18)
=======================================
Autonomous skill acquisition pipeline:
Research → Sandbox Experimentation → Code Generation → Verification → Registration
"""

import asyncio
import hashlib
import json
import os
import subprocess
import tempfile
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from config.settings import STORAGE_DIR

from infrastructure.capability_registry import (
    Capability, CapabilityInterface, CapabilityMetadata, 
    CapabilityType, CapabilityStatus, get_capability_registry
)
from tools.system.tool_creator import scan_risk


SYNTHESIZER_DIR = STORAGE_DIR / "tool_synthesizer"
SYNTHESIZER_DIR.mkdir(parents=True, exist_ok=True)
SYNTHESIZER_DB = str(SYNTHESIZER_DIR / "synthesis.db")
SANDBOX_DIR = SYNTHESIZER_DIR / "sandbox"
SANDBOX_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class SynthesisJob:
    """A tool synthesis job."""
    id: str
    goal: str  # What the tool should do
    requirements: Dict  # Detailed requirements
    status: str = "pending"  # pending, researching, experimenting, generating, verifying, registering, completed, failed
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    research_findings: List[Dict] = field(default_factory=list)
    experiment_results: List[Dict] = field(default_factory=list)
    generated_code: str = ""
    verification_result: Dict = field(default_factory=dict)
    capability_id: Optional[str] = None
    error: str = ""
    metadata: Dict = field(default_factory=dict)


@dataclass
class ResearchFinding:
    """A finding from research phase."""
    source: str  # url, doc, code, api_spec
    content: str
    relevance: float  # 0.0 to 1.0
    metadata: Dict = field(default_factory=dict)


class SandboxExecutor:
    """Safe sandbox for experimenting with code."""
    
    def __init__(self, timeout: int = 30, memory_limit_mb: int = 512):
        self.timeout = timeout
        self.memory_limit_mb = memory_limit_mb
        self._container_image = "python:3.11-slim"  # For docker-based sandbox
    
    def execute(self, code: str, test_input: Dict = None, 
                allowed_imports: List[str] = None) -> Dict:
        """Execute code in sandbox, return result."""
        # Write code to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(code)
            temp_path = f.name
        
        try:
            # Run with subprocess (simpler than docker for now)
            # In production, use gVisor, firecracker, or similar
            cmd = ["python3", temp_path]
            env = os.environ.copy()
            env["PYTHONPATH"] = ""
            
            # Prepare input
            input_data = json.dumps(test_input or {}).encode() if test_input else None
            
            result = subprocess.run(
                cmd,
                input=input_data,
                capture_output=True,
                timeout=self.timeout,
                env=env,
                cwd=str(SANDBOX_DIR)
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout.decode() if result.stdout else "",
                "stderr": result.stderr.decode() if result.stderr else "",
                "returncode": result.returncode,
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Execution timeout", "timeout": True}
        except Exception as e:
            return {"success": False, "error": str(e)}
        finally:
            try:
                os.unlink(temp_path)
            except Exception:
                pass
    
    def execute_with_output_capture(self, code: str, 
                                    capture_vars: List[str] = None) -> Dict:
        """Execute code and capture specific variable values."""
        # Wrap code to capture variables
        wrapper = """
import json
import sys
__captured__ = {}
try:
{code}
except Exception as e:
    __captured__['__error__'] = str(e)
finally:
    # Output captured variables as JSON
    print('__CAPTURE_START__')
    print(json.dumps({{k: v for k, v in __captured__.items() if not k.startswith('_')}}))
    print('__CAPTURE_END__')
"""
        indented_code = '\n'.join('    ' + line for line in code.split('\n'))
        full_code = wrapper.format(code=indented_code)
        
        result = self.execute(full_code)
        if result["success"]:
            # Parse captured output
            stdout = result["stdout"]
            if "__CAPTURE_START__" in stdout and "__CAPTURE_END__" in stdout:
                captured_json = stdout.split("__CAPTURE_START__")[1].split("__CAPTURE_END__")[0].strip()
                try:
                    captured = json.loads(captured_json)
                    result["captured"] = captured
                except Exception:
                    result["captured"] = {}
        return result


class ToolSynthesizer:
    """
    Autonomous tool synthesis pipeline.
    Research → Experiment → Generate → Verify → Register
    """
    
    def __init__(
        self,
        llm_fn: Callable,
        capability_registry: Optional[Any] = None,
        web_search_fn: Optional[Callable] = None,
        sandbox: Optional[SandboxExecutor] = None,
        approval_manager: Optional[Any] = None,
    ):
        self.llm_fn = llm_fn
        self.capability_registry = capability_registry or get_capability_registry()
        self.web_search_fn = web_search_fn
        self.sandbox = sandbox or SandboxExecutor()
        self.approval = approval_manager
        
        self._init_db()
        self._jobs: Dict[str, SynthesisJob] = {}
        self._load_jobs()
    
    def _init_db(self) -> None:
        import sqlite3
        with sqlite3.connect(SYNTHESIZER_DB, check_same_thread=False) as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS synthesis_jobs (
                    id TEXT PRIMARY KEY,
                    goal TEXT NOT NULL,
                    requirements TEXT DEFAULT '{}',
                    status TEXT DEFAULT 'pending',
                    created_at REAL,
                    updated_at REAL,
                    research_findings TEXT DEFAULT '[]',
                    experiment_results TEXT DEFAULT '[]',
                    generated_code TEXT DEFAULT '',
                    verification_result TEXT DEFAULT '{}',
                    capability_id TEXT,
                    error TEXT DEFAULT '',
                    metadata TEXT DEFAULT '{}'
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_job_status ON synthesis_jobs(status)")
    
    def _load_jobs(self) -> None:
        import sqlite3
        with sqlite3.connect(SYNTHESIZER_DB, check_same_thread=False) as c:
            c.row_factory = sqlite3.Row
            rows = c.execute("SELECT * FROM synthesis_jobs WHERE status != 'completed' AND status != 'failed'").fetchall()
            for row in rows:
                job = SynthesisJob(
                    id=row["id"],
                    goal=row["goal"],
                    requirements=json.loads(row["requirements"]),
                    status=row["status"],
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                    research_findings=json.loads(row["research_findings"]),
                    experiment_results=json.loads(row["experiment_results"]),
                    generated_code=row["generated_code"],
                    verification_result=json.loads(row["verification_result"]),
                    capability_id=row["capability_id"],
                    error=row["error"],
                    metadata=json.loads(row["metadata"]),
                )
                self._jobs[job.id] = job
    
    def _save_job(self, job: SynthesisJob) -> None:
        import sqlite3
        job.updated_at = time.time()
        with sqlite3.connect(SYNTHESIZER_DB, check_same_thread=False) as c:
            c.execute("""
                INSERT OR REPLACE INTO synthesis_jobs
                (id, goal, requirements, status, created_at, updated_at,
                 research_findings, experiment_results, generated_code,
                 verification_result, capability_id, error, metadata)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                job.id, job.goal, json.dumps(job.requirements), job.status,
                job.created_at, job.updated_at,
                json.dumps(job.research_findings), json.dumps(job.experiment_results),
                job.generated_code, json.dumps(job.verification_result),
                job.capability_id, job.error, json.dumps(job.metadata)
            ))
    
    def synthesize(self, goal: str, requirements: Dict = None, 
                   async_mode: bool = True) -> str:
        """Start a synthesis job. Returns job ID."""
        job_id = uuid.uuid4().hex[:12]
        job = SynthesisJob(
            id=job_id,
            goal=goal,
            requirements=requirements or {},
            metadata={"async": async_mode}
        )
        self._jobs[job_id] = job
        self._save_job(job)
        
        if async_mode:
            asyncio.create_task(self._run_synthesis(job_id))
        else:
            self._run_synthesis_sync(job_id)
        
        return job_id
    
    async def _run_synthesis(self, job_id: str) -> None:
        job = self._jobs.get(job_id)
        if not job:
            return
        
        try:
            # Phase 1: Research
            job.status = "researching"
            self._save_job(job)
            await self._research_phase(job)
            
            # Phase 2: Experimentation
            job.status = "experimenting"
            self._save_job(job)
            await self._experiment_phase(job)
            
            # Phase 3: Code Generation
            job.status = "generating"
            self._save_job(job)
            await self._generation_phase(job)
            
            # Phase 4: Verification
            job.status = "verifying"
            self._save_job(job)
            await self._verification_phase(job)
            
            # Phase 5: Registration (with approval)
            job.status = "registering"
            self._save_job(job)
            await self._registration_phase(job)
            
            job.status = "completed"
            self._save_job(job)
            
        except Exception as e:
            job.status = "failed"
            job.error = str(e)
            self._save_job(job)
    
    def _run_synthesis_sync(self, job_id: str) -> None:
        """Synchronous version for testing."""
        job = self._jobs.get(job_id)
        if not job:
            return
        
        try:
            job.status = "researching"
            self._save_job(job)
            self._research_phase_sync(job)
            
            job.status = "experimenting"
            self._save_job(job)
            self._experiment_phase_sync(job)
            
            job.status = "generating"
            self._save_job(job)
            self._generation_phase_sync(job)
            
            job.status = "verifying"
            self._save_job(job)
            self._verification_phase_sync(job)
            
            job.status = "registering"
            self._save_job(job)
            self._registration_phase_sync(job)
            
            job.status = "completed"
            self._save_job(job)
            
        except Exception as e:
            job.status = "failed"
            job.error = str(e)
            self._save_job(job)
    
    async def _research_phase(self, job: SynthesisJob) -> None:
        """Research the problem space: search web, docs, APIs, existing code."""
        findings = []
        
        # Generate search queries
        search_prompt = f"""
Goal: {job.goal}
Requirements: {json.dumps(job.requirements)}

Generate 5-8 specific search queries to find:
1. Existing libraries/tools that do this
2. API documentation if integrating with a service
3. Code examples and tutorials
4. Best practices and patterns
5. Potential pitfalls

Return ONLY a JSON array of search query strings.
"""
        try:
            raw = self.llm_fn(search_prompt)
            queries = json.loads(raw[raw.index("["):raw.rindex("]")+1])
        except Exception:
            queries = [job.goal]
        
        # Execute searches
        for query in queries[:8]:
            if self.web_search_fn:
                try:
                    results = await asyncio.get_event_loop().run_in_executor(
                        None, lambda q=query: self.web_search_fn(q)
                    )
                    for r in results[:3]:
                        findings.append(ResearchFinding(
                            source=r.get("url", "search"),
                            content=r.get("snippet", "")[:2000],
                            relevance=0.7,
                            metadata={"query": query, "title": r.get("title", "")}
                        ).__dict__)
                except Exception:
                    pass
        
        # Also search local capability registry for similar tools
        similar = self.capability_registry.search(job.goal, limit=5)
        for cap in similar:
            findings.append(ResearchFinding(
                source=f"capability_registry:{cap.id}",
                content=f"{cap.name}: {cap.interface.description}",
                relevance=0.9,
                metadata={"capability_id": cap.id, "type": cap.metadata.capability_type.value}
            ).__dict__)
        
        job.research_findings = findings
        self._save_job(job)
    
    def _research_phase_sync(self, job: SynthesisJob) -> None:
        asyncio.get_event_loop().run_until_complete(self._research_phase(job))
    
    async def _experiment_phase(self, job: SynthesisJob) -> None:
        """Run experiments in sandbox to validate approaches."""
        if not job.research_findings:
            return
        
        # Generate experiment hypotheses
        exp_prompt = f"""
Goal: {job.goal}
Research findings: {json.dumps([f['content'][:500] for f in job.research_findings[:5]])}

Design 3-5 small code experiments to test different approaches.
Each experiment should be a complete, runnable Python snippet.
Return ONLY a JSON array of experiment objects:
[{{"name": "...", "code": "...", "test_input": {{}}, "hypothesis": "..."}}]
"""
        try:
            raw = self.llm_fn(exp_prompt)
            experiments = json.loads(raw[raw.index("["):raw.rindex("]")+1])
        except Exception:
            experiments = []
        
        # Run experiments
        for exp in experiments[:5]:
            code = exp.get("code", "")
            test_input = exp.get("test_input", {})
            
            # Safety check
            issues = scan_risk(code)
            if issues:
                job.experiment_results.append({
                    "name": exp.get("name"),
                    "skipped": True,
                    "reason": f"Safety scan failed: {issues}",
                })
                continue
            
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda c=code, ti=test_input: self.sandbox.execute(c, ti)
            )
            
            job.experiment_results.append({
                "name": exp.get("name"),
                "hypothesis": exp.get("hypothesis"),
                "code": code,
                "result": result,
                "success": result.get("success", False),
            })
        
        self._save_job(job)
    
    def _experiment_phase_sync(self, job: SynthesisJob) -> None:
        asyncio.get_event_loop().run_until_complete(self._experiment_phase(job))
    
    async def _generation_phase(self, job: SynthesisJob) -> None:
        """Generate the final tool implementation."""
        # Synthesize learnings from experiments
        successful_exps = [e for e in job.experiment_results if e.get("success")]
        
        gen_prompt = f"""
Goal: {job.goal}
Requirements: {json.dumps(job.requirements)}
Research findings: {json.dumps([f['content'][:300] for f in job.research_findings[:5]])}
Successful experiments: {json.dumps([e['name'] for e in successful_exps])}

Generate a complete, production-ready Python tool that:
1. Has a clear function signature with type hints
2. Includes comprehensive error handling
3. Has docstrings and examples
4. Follows the capability interface pattern:
   - Defines register_tools(registry) function
   - Tool function takes (query: str, **kwargs) -> str
   - Returns JSON-serializable result
5. Uses only safe imports (no subprocess, socket, eval, etc.)
6. Is self-contained and doesn't require external dependencies not in stdlib

Return ONLY the complete Python code as a string.
"""
        try:
            code = self.llm_fn(gen_prompt)
            # Extract code from markdown if present
            if "```python" in code:
                code = code.split("```python")[1].split("```")[0]
            elif "```" in code:
                code = code.split("```")[1].split("```")[0]
            job.generated_code = code.strip()
        except Exception as e:
            job.error = f"Generation failed: {e}"
            raise
        
        self._save_job(job)
    
    def _generation_phase_sync(self, job: SynthesisJob) -> None:
        asyncio.get_event_loop().run_until_complete(self._generation_phase(job))
    
    async def _verification_phase(self, job: SynthesisJob) -> None:
        """Verify the generated code with test cases."""
        if not job.generated_code:
            job.verification_result = {"passed": False, "error": "No code generated"}
            return
        
        # Safety scan
        issues = scan_risk(job.generated_code)
        if issues:
            job.verification_result = {"passed": False, "error": f"Safety scan failed: {issues}"}
            return
        
        # Generate test cases
        test_prompt = f"""
Tool code: {job.generated_code[:3000]}
Goal: {job.goal}

Generate 5-10 test cases as JSON array:
[{{"input": {{...}}, "expected": {...}, "description": "..."}}]
Cover: normal cases, edge cases, error cases, empty inputs.
"""
        try:
            raw = self.llm_fn(test_prompt)
            test_cases = json.loads(raw[raw.index("["):raw.rindex("]")+1])
        except Exception:
            test_cases = []
        
        # Run verification through capability registry
        # Create a temporary capability for testing
        temp_id = f"temp_{job.id}"
        temp_cap = Capability(
            id=temp_id,
            name=f"synth_{job.id}",
            interface=CapabilityInterface(
                name=f"synth_{job.id}",
                description=job.goal,
                input_schema={"type": "object", "properties": {}},
                output_schema={"type": "string"},
            ),
            metadata=CapabilityMetadata(
                capability_type=CapabilityType.TOOL,
                domain_tags=["synthesized"],
                test_cases=test_cases,
            ),
            implementation=job.generated_code,
            entry_point="main",  # Will be adjusted
        )
        
        # Find the actual entry point
        entry_point = self._find_entry_point(job.generated_code)
        temp_cap.entry_point = entry_point
        
        # Run verification
        verification = self.capability_registry.verify(temp_id, test_cases)
        job.verification_result = verification
        
        if not verification.get("passed"):
            # Try to fix and re-verify (one retry)
            await self._fix_and_reverify(job, verification)
        
        self._save_job(job)
    
    def _find_entry_point(self, code: str) -> str:
        """Find the main function entry point in generated code."""
        import ast
        try:
            tree = ast.parse(code)
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef) and not node.name.startswith('_'):
                    # Prefer functions named main, run, execute, or the tool name
                    if node.name in ('main', 'run', 'execute', 'tool', 'process'):
                        return node.name
                    # Otherwise return first non-private function
                    return node.name
        except Exception:
            pass
        return "main"
    
    async def _fix_and_reverify(self, job: SynthesisJob, verification: Dict) -> None:
        """Attempt to fix failed tests and re-verify."""
        failed_tests = [r for r in verification.get("results", []) if not r.get("passed")]
        if not failed_tests:
            return
        
        fix_prompt = f"""
Code: {job.generated_code[:3000]}
Failed tests: {json.dumps(failed_tests[:3])}
Goal: {job.goal}

Fix the code to pass the failed tests. Return ONLY the complete corrected Python code.
"""
        try:
            fixed_code = self.llm_fn(fix_prompt)
            if "```python" in fixed_code:
                fixed_code = fixed_code.split("```python")[1].split("```")[0]
            elif "```" in fixed_code:
                fixed_code = fixed_code.split("```")[1].split("```")[0]
            
            job.generated_code = fixed_code.strip()
            
            # Re-verify
            temp_id = f"temp_{job.id}"
            temp_cap = Capability(
                id=temp_id,
                name=f"synth_{job.id}",
                interface=CapabilityInterface(
                    name=f"synth_{job.id}",
                    description=job.goal,
                    input_schema={"type": "object"},
                    output_schema={"type": "string"},
                ),
                metadata=CapabilityMetadata(
                    capability_type=CapabilityType.TOOL,
                    domain_tags=["synthesized"],
                    test_cases=verification.get("results", []),
                ),
                implementation=job.generated_code,
                entry_point=self._find_entry_point(job.generated_code),
            )
            
            verification = self.capability_registry.verify(temp_id, verification.get("results", []))
            job.verification_result = verification
            
        except Exception:
            pass
    
    def _verification_phase_sync(self, job: SynthesisJob) -> None:
        asyncio.get_event_loop().run_until_complete(self._verification_phase(job))
    
    async def _registration_phase(self, job: SynthesisJob) -> None:
        """Register the verified capability (with approval gate)."""
        if not job.verification_result.get("passed"):
            job.error = "Verification failed"
            return
        
        # Check approval for new tool creation
        if self.approval and self.approval.needs_approval(
            f"synthesize_tool:{job.goal[:50]}", risk_level="high"
        ):
            approved = self.approval.request_approval(
                action=f"Register synthesized tool for: {job.goal[:80]}",
                reason=f"Autonomous tool synthesis from goal: {job.goal}",
                risk_level="high",
            )
            if not approved:
                job.error = "Human approval denied"
                job.status = "blocked"
                return
        
        # Create capability
        cap_name = self._generate_capability_name(job.goal)
        cap_id = f"synth_{job.id}"
        
        interface = CapabilityInterface(
            name=cap_name,
            description=job.goal,
            input_schema={"type": "object", "properties": {"query": {"type": "string"}}},
            output_schema={"type": "string"},
            examples=job.requirements.get("examples", []),
        )
        
        metadata = CapabilityMetadata(
            capability_type=CapabilityType.TOOL,
            domain_tags=job.requirements.get("domain_tags", ["synthesized"]),
            version="1.0.0",
            author="maya_synthesizer",
            verification_status=CapabilityStatus.VERIFIED,
            test_cases=job.verification_result.get("results", []),
            provenance={
                "synthesis_job_id": job.id,
                "goal": job.goal,
                "research_sources": len(job.research_findings),
                "experiments_run": len(job.experiment_results),
                "verification_score": job.verification_result.get("score", 0),
            },
        )
        
        capability = Capability(
            id=cap_id,
            name=cap_name,
            interface=interface,
            metadata=metadata,
            implementation=job.generated_code,
            entry_point=self._find_entry_point(job.generated_code),
        )
        
        registered_id = self.capability_registry.register(capability)
        job.capability_id = registered_id
        self._save_job(job)
    
    def _registration_phase_sync(self, job: SynthesisJob) -> None:
        asyncio.get_event_loop().run_until_complete(self._registration_phase(job))
    
    def _generate_capability_name(self, goal: str) -> str:
        """Generate a valid capability name from goal."""
        # Extract key verbs/nouns
        words = goal.lower().split()
        verbs = [w for w in words if w in ('create', 'build', 'make', 'generate', 'convert', 
                                            'parse', 'extract', 'transform', 'analyze', 'search',
                                            'fetch', 'download', 'upload', 'deploy', 'run')]
        nouns = [w for w in words if w not in verbs and len(w) > 3]
        
        name_parts = verbs[:1] + nouns[:2]
        if not name_parts:
            name_parts = ["tool"]
        
        return "_".join(name_parts)[:50]
    
    def get_job(self, job_id: str) -> Optional[SynthesisJob]:
        return self._jobs.get(job_id)
    
    def list_jobs(self, status: str = None, limit: int = 50) -> List[SynthesisJob]:
        jobs = list(self._jobs.values())
        if status:
            jobs = [j for j in jobs if j.status == status]
        jobs.sort(key=lambda j: j.created_at, reverse=True)
        return jobs[:limit]
    
    def get_status(self) -> Dict:
        return {
            "total_jobs": len(self._jobs),
            "by_status": {
                status: len([j for j in self._jobs.values() if j.status == status])
                for status in ["pending", "researching", "experimenting", "generating", 
                              "verifying", "registering", "completed", "failed", "blocked"]
            },
            "recent_jobs": [
                {"id": j.id, "goal": j.goal[:80], "status": j.status, "capability_id": j.capability_id}
                for j in sorted(self._jobs.values(), key=lambda j: j.created_at, reverse=True)[:10]
            ],
        }


# Module singleton
_tool_synthesizer: Optional[ToolSynthesizer] = None


def get_tool_synthesizer(llm_fn=None, **kwargs) -> ToolSynthesizer:
    global _tool_synthesizer
    if _tool_synthesizer is None and llm_fn:
        _tool_synthesizer = ToolSynthesizer(llm_fn, **kwargs)
    return _tool_synthesizer


def set_tool_synthesizer(synthesizer: ToolSynthesizer) -> None:
    global _tool_synthesizer
    _tool_synthesizer = synthesizer