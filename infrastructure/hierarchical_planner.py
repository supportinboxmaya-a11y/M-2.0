"""
Maya 2.0 — Hierarchical Planner (Phase 18)
===========================================
HTN (Hierarchical Task Network) planner with MCTS for tactical decisions,
contingency planning, and resource-aware scheduling.
"""

import asyncio
import json
import math
import random
import time
import uuid
from collections import deque
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
from enum import Enum

from infrastructure.capability_registry import CapabilityType, get_capability_registry
from infrastructure.world_models import WorldModel, Action, SimulationResult, create_world_models
from infrastructure.cognitive_kernel import CognitiveKernel, Goal, GoalStatus, GoalPriority


class PlanStatus(Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    EXECUTING = "executing"
    COMPLETED = "completed"
    FAILED = "failed"
    REPLANNING = "replanning"
    SUSPENDED = "suspended"


@dataclass
class PlanStep:
    """A single step in a plan."""
    id: str
    name: str
    description: str
    action: Dict  # {type, parameters, domain}
    expected_outcome: Dict
    preconditions: List[str] = field(default_factory=list)
    effects: List[str] = field(default_factory=list)
    required_capability: str = ""
    contingency: Optional["PlanStep"] = None
    depends_on: List[str] = field(default_factory=list)  # Step IDs
    estimated_duration: float = 60.0  # seconds
    estimated_cost: float = 0.0
    status: str = "pending"  # pending, running, completed, failed, skipped
    result: Optional[Dict] = None
    started_at: Optional[float] = None
    completed_at: Optional[float] = None


@dataclass
class ContingencyPlan:
    """A contingency branch for a plan."""
    trigger_condition: str  # e.g., "step_3_failed", "timeout", "resource_exhausted"
    trigger_step: str
    alternative_steps: List[PlanStep]
    probability: float = 0.1
    estimated_additional_cost: float = 0.0


@dataclass
class Plan:
    """A hierarchical plan with contingencies."""
    id: str
    goal_id: str
    root_task: str  # High-level task name
    steps: List[PlanStep] = field(default_factory=list)
    contingencies: List[ContingencyPlan] = field(default_factory=list)
    status: PlanStatus = PlanStatus.DRAFT
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    resource_budget: Dict = field(default_factory=dict)
    checkpoints: List[Dict] = field(default_factory=list)
    current_step_index: int = 0
    
    def get_step(self, step_id: str) -> Optional[PlanStep]:
        for step in self.steps:
            if step.id == step_id:
                return step
        return None
    
    def get_pending_steps(self) -> List[PlanStep]:
        return [s for s in self.steps if s.status == "pending"]
    
    def get_next_executable_step(self) -> Optional[PlanStep]:
        """Get next step whose dependencies are satisfied."""
        for step in self.steps:
            if step.status != "pending":
                continue
            deps_met = all(
                self.get_step(dep_id) and self.get_step(dep_id).status == "completed"
                for dep_id in step.depends_on
            )
            if deps_met:
                return step
        return None


class HTNMethod:
    """An HTN method for decomposing a task."""
    
    def __init__(self, task_name: str, subtasks: List[Dict], preconditions: List[str] = None):
        self.task_name = task_name
        self.subtasks = subtasks  # List of {name, description, action, ...}
        self.preconditions = preconditions or []
    
    def applicable(self, state: Dict) -> bool:
        """Check if method preconditions are met."""
        for precond in self.preconditions:
            if not self._check_precondition(precond, state):
                return False
        return True
    
    def _check_precondition(self, precond: str, state: Dict) -> bool:
        """Check a single precondition."""
        # Simple precondition checking
        if precond.startswith("has_capability:"):
            cap_name = precond.split(":")[1]
            reg = get_capability_registry()
            return reg.get_by_name(cap_name) is not None
        elif precond.startswith("belief:"):
            # Would check kernel beliefs
            return True
        return True


class HTNPlanner:
    """Hierarchical Task Network planner."""
    
    def __init__(self, kernel: CognitiveKernel, world_models: Dict[str, WorldModel]):
        self.kernel = kernel
        self.world_models = world_models
        self.methods: Dict[str, List[HTNMethod]] = {}
        self._register_default_methods()
    
    def _register_default_methods(self) -> None:
        """Register default decomposition methods."""
        # Software development methods
        self.add_method(HTNMethod("build_software", [
            {"name": "analyze_requirements", "description": "Analyze and document requirements"},
            {"name": "design_architecture", "description": "Design system architecture"},
            {"name": "implement_core", "description": "Implement core functionality"},
            {"name": "write_tests", "description": "Write unit and integration tests"},
            {"name": "deploy", "description": "Deploy to target environment"},
        ], ["has_capability:code_generation"]))
        
        self.add_method(HTNMethod("deploy_application", [
            {"name": "prepare_build", "description": "Prepare build artifacts"},
            {"name": "build_image", "description": "Build Docker image"},
            {"name": "push_image", "description": "Push to registry"},
            {"name": "deploy_container", "description": "Deploy container to server"},
            {"name": "verify_deployment", "description": "Verify deployment health"},
        ], ["has_capability:docker_build", "has_capability:remote_deploy"]))
        
        # Research methods
        self.add_method(HTNMethod("research_topic", [
            {"name": "define_scope", "description": "Define research scope and questions"},
            {"name": "search_sources", "description": "Search web, papers, documentation"},
            {"name": "extract_insights", "description": "Extract key insights from sources"},
            {"name": "synthesize_report", "description": "Synthesize findings into report"},
        ], []))
        
        # File operations
        self.add_method(HTNMethod("process_files", [
            {"name": "discover_files", "description": "Find relevant files"},
            {"name": "read_content", "description": "Read file contents"},
            {"name": "transform_content", "description": "Apply transformations"},
            {"name": "write_output", "description": "Write results"},
        ], ["has_capability:file_operations"]))
    
    def add_method(self, method: HTNMethod) -> None:
        self.methods.setdefault(method.task_name, []).append(method)
    
    def decompose(self, task_name: str, state: Dict, depth: int = 0) -> List[Dict]:
        """Decompose a task into subtasks using HTN methods."""
        if depth > 5:  # Prevent infinite recursion
            return [{"name": task_name, "description": task_name, "primitive": True}]
        
        methods = self.methods.get(task_name, [])
        for method in methods:
            if method.applicable(state):
                # Found applicable method
                subtasks = []
                for subtask in method.subtasks:
                    # Recursively decompose
                    decomposed = self.decompose(subtask["name"], state, depth + 1)
                    if len(decomposed) == 1 and decomposed[0].get("primitive"):
                        subtasks.append(subtask)
                    else:
                        subtasks.extend(decomposed)
                return subtasks
        
        # No applicable method - treat as primitive
        return [{"name": task_name, "description": task_name, "primitive": True}]
    
    def create_plan(self, goal: Goal, state: Dict = None) -> Plan:
        """Create a hierarchical plan for a goal."""
        state = state or {}
        plan_id = uuid.uuid4().hex[:12]
        
        # Decompose goal into primitive tasks
        # Use goal description as initial task
        primitive_tasks = self.decompose(goal.description[:50].replace(" ", "_"), state)
        
        # Convert to plan steps
        steps = []
        for i, task in enumerate(primitive_tasks):
            step = PlanStep(
                id=f"step_{i}_{uuid.uuid4().hex[:6]}",
                name=task.get("name", task.get("description", f"task_{i}")),
                description=task.get("description", ""),
                action=task.get("action", {"type": "generic", "parameters": {}}),
                expected_outcome=task.get("expected_outcome", {}),
                required_capability=task.get("required_capability", ""),
                depends_on=[steps[-1].id] if steps else [],
            )
            steps.append(step)
        
        # Generate contingencies
        contingencies = self._generate_contingencies(steps)
        
        # Estimate resources
        resource_budget = self._estimate_resources(steps)
        
        plan = Plan(
            id=plan_id,
            goal_id=goal.id,
            root_task=goal.description[:50],
            steps=steps,
            contingencies=contingencies,
            resource_budget=resource_budget,
        )
        
        return plan
    
    def _generate_contingencies(self, steps: List[PlanStep]) -> List[ContingencyPlan]:
        """Generate contingency plans for critical steps."""
        contingencies = []
        
        for step in steps:
            # Add failure contingency for each step
            if step.required_capability:
                # Find alternative capabilities
                reg = get_capability_registry()
                alternatives = reg.find_composable(step.required_capability, limit=2)
                if alternatives:
                    alt_steps = []
                    for alt in alternatives:
                        alt_step = PlanStep(
                            id=f"contingency_{step.id}_{alt.id}",
                            name=f"Alternative: {alt.name}",
                            description=f"Use {alt.name} instead",
                            action={"type": "use_capability", "capability_id": alt.id},
                            expected_outcome={"fallback": True},
                            required_capability=alt.id,
                        )
                        alt_steps.append(alt_step)
                    
                    if alt_steps:
                        contingencies.append(ContingencyPlan(
                            trigger_condition=f"{step.id}_failed",
                            trigger_step=step.id,
                            alternative_steps=alt_steps,
                            probability=0.15,
                            estimated_additional_cost=sum(s.estimated_cost for s in alt_steps),
                        ))
            
            # Timeout contingency
            contingencies.append(ContingencyPlan(
                trigger_condition=f"{step.id}_timeout",
                trigger_step=step.id,
                alternative_steps=[PlanStep(
                    id=f"retry_{step.id}",
                    name=f"Retry {step.name}",
                    description="Retry with increased timeout",
                    action=step.action,
                    expected_outcome=step.expected_outcome,
                    required_capability=step.required_capability,
                    estimated_duration=step.estimated_duration * 2,
                )],
                probability=0.1,
                estimated_additional_cost=step.estimated_cost * 0.5,
            ))
        
        return contingencies
    
    def _estimate_resources(self, steps: List[PlanStep]) -> Dict:
        total_time = sum(s.estimated_duration for s in steps)
        total_cost = sum(s.estimated_cost for s in steps)
        api_calls = sum(1 for s in steps if s.required_capability)
        
        return {
            "estimated_duration_seconds": total_time,
            "estimated_cost_usd": total_cost,
            "estimated_api_calls": api_calls,
            "parallelizable_steps": len([s for s in steps if not s.depends_on]),
        }


class MCTSNode:
    """Monte Carlo Tree Search node for tactical planning."""
    
    def __init__(self, state: Dict, parent: Optional["MCTSNode"] = None, action: Action = None):
        self.state = state
        self.parent = parent
        self.action = action
        self.children: List[MCTSNode] = []
        self.visits = 0
        self.value = 0.0
        self.untried_actions: List[Action] = []
    
    def ucb1(self, exploration: float = 1.414) -> float:
        if self.visits == 0:
            return float('inf')
        return self.value / self.visits + exploration * math.sqrt(math.log(self.parent.visits) / self.visits)
    
    def expand(self, actions: List[Action]) -> "MCTSNode":
        action = actions.pop()
        # Simulate action to get new state
        # For simplicity, we just create a new state
        new_state = self.state.copy()
        new_state["last_action"] = action.action_type
        new_state["step"] = self.state.get("step", 0) + 1
        child = MCTSNode(new_state, self, action)
        self.children.append(child)
        return child
    
    def is_terminal(self, max_depth: int = 10) -> bool:
        return self.state.get("step", 0) >= max_depth or self.state.get("goal_achieved", False)
    
    def best_child(self, exploration: float = 1.414) -> "MCTSNode":
        return max(self.children, key=lambda c: c.ucb1(exploration))


class MCTSPlanner:
    """Monte Carlo Tree Search for tactical decision making."""
    
    def __init__(self, world_models: Dict[str, WorldModel], 
                 kernel: CognitiveKernel, iterations: int = 100):
        self.world_models = world_models
        self.kernel = kernel
        self.iterations = iterations
    
    def search(self, initial_state: Dict, goal: Goal, 
               available_actions: List[Action]) -> Optional[Action]:
        """Run MCTS to find best next action."""
        root = MCTSNode(initial_state)
        root.untried_actions = available_actions.copy()
        
        for _ in range(self.iterations):
            node = self._select(root)
            if not node.is_terminal() and node.untried_actions:
                node = node.expand(node.untried_actions)
            reward = self._simulate(node, goal)
            self._backpropagate(node, reward)
        
        if not root.children:
            return None
        
        # Return best action
        best_child = max(root.children, key=lambda c: c.visits)
        return best_child.action
    
    def _select(self, node: MCTSNode) -> MCTSNode:
        """Select node using UCB1."""
        while not node.is_terminal() and node.untried_actions == [] and node.children:
            node = node.best_child()
        return node
    
    def _simulate(self, node: MCTSNode, goal: Goal) -> float:
        """Simulate random playout to estimate value."""
        state = node.state.copy()
        total_reward = 0.0
        steps = 0
        
        while steps < 20 and not state.get("goal_achieved", False):
            # Get available actions
            actions = self._get_available_actions(state)
            if not actions:
                break
            
            action = random.choice(actions)
            # Simulate using world model
            domain = action.parameters.get("domain", "general")
            model = self.world_models.get(domain)
            if model:
                result = model.simulate(action)
                if result.success:
                    total_reward += result.reward
                    # Update state based on effects
                    for effect in result.effects:
                        state[f"effect_{effect.get('type', 'unknown')}"] = effect
                else:
                    total_reward -= 0.5
            steps += 1
            state["step"] = steps
        
        # Bonus for goal achievement
        if state.get("goal_achieved", False):
            total_reward += 10.0
        
        return total_reward
    
    def _get_available_actions(self, state: Dict) -> List[Action]:
        """Get available actions for current state."""
        actions = []
        reg = get_capability_registry()
        capabilities = reg.list_capabilities(limit=20)
        
        for cap in capabilities:
            if cap.metadata.capability_type == CapabilityType.TOOL:
                actions.append(Action(
                    action_type="use_tool",
                    parameters={"capability_id": cap.id, "domain": cap.metadata.domain_tags[0] if cap.metadata.domain_tags else "general"},
                ))
        
        # Add domain-specific actions
        for domain, model in self.world_models.items():
            if domain == "filesystem":
                actions.extend([
                    Action("read_file", {"path": "/tmp/test.txt", "domain": "filesystem"}),
                    Action("list_dir", {"path": ".", "domain": "filesystem"}),
                ])
            elif domain == "docker":
                actions.append(Action("run_container", {"name": "test", "image": "nginx", "domain": "docker"}))
        
        return actions[:15]  # Limit branching factor
    
    def _backpropagate(self, node: MCTSNode, reward: float) -> None:
        """Backpropagate reward up the tree."""
        while node:
            node.visits += 1
            node.value += reward
            node = node.parent


class HierarchicalPlanner:
    """
    Main planner combining HTN for strategic planning and MCTS for tactical decisions.
    """
    
    def __init__(self, kernel: CognitiveKernel, world_models: Dict[str, WorldModel] = None,
                 capability_registry=None):
        self.kernel = kernel
        self.world_models = world_models or create_world_models()
        self.capability_registry = capability_registry or get_capability_registry()
        
        self.htn = HTNPlanner(kernel, self.world_models)
        self.mcts = MCTSPlanner(self.world_models, kernel)
        
        self.active_plans: Dict[str, Plan] = {}
        self.plan_history: List[Plan] = []
    
    def plan_for_goal(self, goal: Goal) -> Plan:
        """Create a complete hierarchical plan for a goal."""
        # Get current world state
        state = self._get_world_state()
        
        # Create HTN plan
        plan = self.htn.create_plan(goal, state)
        
        # Refine with MCTS for first few steps
        if plan.steps:
            initial_state = {"step": 0, "goal": goal.description}
            available_actions = self.mcts._get_available_actions(initial_state)
            best_action = self.mcts.search(initial_state, goal, available_actions)
            if best_action:
                # Update first step with MCTS recommendation
                plan.steps[0].action = {
                    "type": best_action.action_type,
                    "parameters": best_action.parameters
                }
        
        self.active_plans[plan.id] = plan
        self.kernel._audit("plan_created", f"Plan {plan.id} for goal {goal.id}: {len(plan.steps)} steps")
        
        return plan
    
    def execute_plan(self, plan_id: str, executor: Callable[[PlanStep], Dict]) -> Dict:
        """Execute a plan step by step with monitoring and contingencies."""
        plan = self.active_plans.get(plan_id)
        if not plan:
            return {"error": "Plan not found", "success": False}
        
        plan.status = PlanStatus.EXECUTING
        plan.updated_at = time.time()
        
        results = []
        
        while plan.current_step_index < len(plan.steps):
            step = plan.steps[plan.current_step_index]
            
            # Check if we should trigger a contingency
            if self._should_trigger_contingency(plan, step):
                contingency = self._find_contingency(plan, step)
                if contingency:
                    self._execute_contingency(plan, contingency, executor)
                    continue
            
            # Execute step
            step.status = "running"
            step.started_at = time.time()
            self.kernel._audit("plan_step_start", f"Plan {plan_id} step {step.id}: {step.name}")
            
            try:
                result = executor(step)
                step.result = result
                step.completed_at = time.time()
                step.duration = step.completed_at - step.started_at
                
                if result.get("success", False):
                    step.status = "completed"
                    plan.checkpoints.append({
                        "step_id": step.id,
                        "timestamp": time.time(),
                        "success": True,
                        "result": result
                    })
                    self.kernel._audit("plan_step_complete", f"Step {step.id} completed")
                else:
                    step.status = "failed"
                    plan.checkpoints.append({
                        "step_id": step.id,
                        "timestamp": time.time(),
                        "success": False,
                        "error": result.get("error")
                    })
                    self.kernel._audit("plan_step_failed", f"Step {step.id} failed: {result.get('error')}")
                    
                    # Check for contingency
                    contingency = self._find_contingency(plan, step)
                    if contingency:
                        self._execute_contingency(plan, contingency, executor)
                        continue
                    else:
                        # No contingency - mark plan failed
                        plan.status = PlanStatus.FAILED
                        return {"success": False, "plan_id": plan_id, "failed_step": step.id, "results": results}
                
            except Exception as e:
                step.status = "failed"
                step.result = {"error": str(e)}
                self.kernel._audit("plan_step_error", f"Step {step.id} exception: {e}")
                plan.status = PlanStatus.FAILED
                return {"success": False, "plan_id": plan_id, "failed_step": step.id, "error": str(e), "results": results}
            
            results.append({"step_id": step.id, "success": step.status == "completed", "result": step.result})
            plan.current_step_index += 1
            plan.updated_at = time.time()
        
        plan.status = PlanStatus.COMPLETED
        self.plan_history.append(plan)
        self.kernel._audit("plan_completed", f"Plan {plan_id} completed successfully")
        
        return {"success": True, "plan_id": plan_id, "results": results}
    
    def _should_trigger_contingency(self, plan: Plan, step: PlanStep) -> bool:
        """Check if a contingency should be triggered."""
        if step.status == "failed":
            return True
        if step.started_at and time.time() - step.started_at > step.estimated_duration * 3:
            return True  # Timeout
        return False
    
    def _find_contingency(self, plan: Plan, step: PlanStep) -> Optional[ContingencyPlan]:
        """Find applicable contingency for a step."""
        for contingency in plan.contingencies:
            if contingency.trigger_step == step.id:
                if contingency.trigger_condition in [f"{step.id}_failed", f"{step.id}_timeout"]:
                    return contingency
        return None
    
    def _execute_contingency(self, plan: Plan, contingency: ContingencyPlan, executor: Callable) -> None:
        """Execute a contingency plan."""
        self.kernel._audit("contingency_triggered", f"Plan {plan.id} contingency: {contingency.trigger_condition}")
        
        # Insert contingency steps before current step
        insert_index = plan.current_step_index
        for alt_step in contingency.alternative_steps:
            plan.steps.insert(insert_index, alt_step)
            insert_index += 1
        
        # Don't advance current_step_index - will execute first contingency step next
    
    def replan(self, plan_id: str, from_step: int = None, reason: str = "") -> Plan:
        """Replan from a specific step."""
        plan = self.active_plans.get(plan_id)
        if not plan:
            raise ValueError(f"Plan not found: {plan_id}")
        
        if from_step is None:
            from_step = plan.current_step_index
        
        plan.status = PlanStatus.REPLANNING
        self.kernel._audit("replan_start", f"Replanning {plan_id} from step {from_step}: {reason}")
        
        # Get current goal
        goal = self.kernel.get_goal(plan.goal_id)
        if not goal:
            raise ValueError(f"Goal not found: {plan.goal_id}")
        
        # Create new plan from current state
        new_plan = self.plan_for_goal(goal)
        
        # Preserve completed steps
        completed_steps = plan.steps[:from_step]
        new_plan.steps = completed_steps + new_plan.steps
        
        # Update status
        new_plan.status = PlanStatus.ACTIVE
        new_plan.current_step_index = from_step
        
        self.active_plans[plan_id] = new_plan
        self.kernel._audit("replan_complete", f"Plan {plan_id} replanned: {len(new_plan.steps)} steps")
        
        return new_plan
    
    def _get_world_state(self) -> Dict:
        """Get combined world state from all models."""
        state = {}
        for domain, model in self.world_models.items():
            try:
                observations = model.observe()
                state[domain] = observations
            except Exception:
                state[domain] = []
        return state
    
    def get_plan_status(self, plan_id: str) -> Optional[Dict]:
        plan = self.active_plans.get(plan_id)
        if not plan:
            return None
        
        completed = sum(1 for s in plan.steps if s.status == "completed")
        failed = sum(1 for s in plan.steps if s.status == "failed")
        
        return {
            "plan_id": plan.id,
            "goal_id": plan.goal_id,
            "status": plan.status.value,
            "progress": completed / len(plan.steps) if plan.steps else 0,
            "steps_total": len(plan.steps),
            "steps_completed": completed,
            "steps_failed": failed,
            "current_step": plan.steps[plan.current_step_index].id if plan.current_step_index < len(plan.steps) else None,
            "resource_budget": plan.resource_budget,
        }
    
    def list_active_plans(self) -> List[Dict]:
        return [self.get_plan_status(pid) for pid in self.active_plans]


# Module singleton
_hierarchical_planner: Optional[HierarchicalPlanner] = None


def get_hierarchical_planner(kernel=None, world_models=None, **kwargs) -> HierarchicalPlanner:
    global _hierarchical_planner
    if _hierarchical_planner is None and kernel:
        _hierarchical_planner = HierarchicalPlanner(kernel, world_models, **kwargs)
    return _hierarchical_planner


def set_hierarchical_planner(planner: HierarchicalPlanner) -> None:
    global _hierarchical_planner
    _hierarchical_planner = planner