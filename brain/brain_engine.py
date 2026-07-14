"""
Maya 2.0 - Workflow Engine
Drives the orchestration loop, executes graph nodes, 
and coordinates live fallback interventions upon failures.
"""

import time
from typing import Dict, List, Optional
from brain.brain_engine import BrainEngine
from brain.task_graph import TaskGraph
from llm.router import LLMRouter
from core.executor import Executor

class WorkflowEngine:
    def __init__(self, router: Optional[LLMRouter] = None, executor: Optional[Executor] = None):
        self.router = router or LLMRouter()
        self.executor = executor or Executor()
        
        # Correctly pass self.router to BrainEngine to empower FallbackManager
        self.brain = BrainEngine(llm_fn=self._router_call, router=self.router)
        self.graph: Optional[TaskGraph] = None
        self.current_goal: str = ""

    def run(self, goal: str) -> str:
        """Executes a complete goal through structured step decomposition and validation."""
        self.current_goal = goal
        print(f"\n🚀 [Workflow Started]: Processing goal -> '{goal}'")
        
        # 1. Analyze and Plan steps
        analysis = self.brain.analyze(goal)
        steps = analysis.get("steps", [])
        if not steps:
            return "Failed to parse actionable steps from the goal."
            
        # 2. Build DAG Task Graph
        self.graph = self.brain.build_graph(steps)
        results = []

        # 3. Execution Cycle Loop
        while not self.graph.is_complete():
            ready_nodes = self.graph.get_ready()
            if not ready_nodes and not self.graph.is_complete():
                print("⚠️ [Deadlock]: Active dependency conflict detected in task layers.")
                break

            for node_id in ready_nodes:
                node = self.graph.nodes[node_id]
                print(f"\n⚙️ [Executing Step]: {node.description}")
                
                try:
                    # Execute node utilizing tools/agents context
                    out, success = self.executor.execute_node(node)
                    
                    # Record execution results with context and fix missing goal argument
                    res = self.brain.record(self.graph, node_id, str(out), verified=success, goal=goal)
                    results.append(res)
                    
                    # Handle real-time recovery injections if a node breakdown is detected
                    if not res.get("ok") and res.get("fallback_triggered"):
                        recovery = res.get("recovery", {})
                        if recovery.get("should_abort"):
                            print(f"🛑 [Workflow Aborted]: {recovery.get('reason')}")
                            return f"Workflow aborted during execution: {recovery.get('reason')}"
                            
                        # Dynamic execution path patching
                        new_steps = recovery.get("new_steps", [])
                        if new_steps:
                            print(f"🔄 [Injecting Mitigation Steps]: {recovery.get('message')}")
                            # Re-inject new conditional branches cleanly into graph runtime topology
                            for s in new_steps:
                                self.graph.add_node_dynamically(s)
                                
                except Exception as e:
                    # Catch raw exceptions and utilize the router's smart diagnostic interpreter
                    raw_err = str(e)
                    readable_err = self.router._interpret_error("Workflow Runtime", raw_err)
                    print(f"\n🛑 [Critical Runtime Failure]: {readable_err}")
                    
                    self.graph.fail(node_id, error=raw_err)
                    return f"Execution halted due to unhandled runtime crash: {raw_err}"

        # 4. Final Plan Confidence Evaluation Check
        summary_evaluation = self.brain.plan_confidence(results)
        if summary_evaluation.get("should_replan"):
            print("🔄 [Low Global Score Summary]: Triggering systemic optimization loops...")
            
        print("\n✅ [Workflow Completed Successfully] All downstream graph branches satisfied.\n")
        return "Goal executed successfully."

    def _router_call(self, messages: List[Dict], model: Optional[str] = None) -> str:
        """Gateway wrapper redirecting underlying planning steps back through the unified LLMRouter."""
        return self.router.chat(messages=messages, model=model)

