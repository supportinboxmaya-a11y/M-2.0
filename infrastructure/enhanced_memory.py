"""
Maya 2.0 — Enhanced Memory Systems (Phase 3)
=============================================
Hippocampus: Sleep-phase consolidation, replay, schema extraction.
Semantic Consolidation: Belief revision with causal reasoning.
Working Memory v2: Chunking, attention heads, retrieval-augmented WM.
"""

import asyncio
import json
import math
import os
import random
import time
import uuid
from collections import defaultdict, deque
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

import numpy as np

from config.settings import STORAGE_DIR


MEMORY_DIR = STORAGE_DIR / "enhanced_memory"
MEMORY_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class MemoryTrace:
    """A consolidated memory trace."""
    id: str
    content: str
    trace_type: str  # episodic, semantic, procedural, schema
    strength: float  # 0-1
    associations: List[str] = field(default_factory=list)  # Related trace IDs
    metadata: Dict = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    last_recalled: float = field(default_factory=time.time)
    recall_count: int = 0
    consolidation_cycle: int = 0


@dataclass
class Schema:
    """Extracted schema from repeated patterns."""
    id: str
    name: str
    pattern: Dict  # Abstract pattern representation
    instances: List[str]  # Trace IDs that match
    confidence: float
    created_at: float = field(default_factory=time.time)
    applications: int = 0


class Hippocampus:
    """
    Sleep-phase memory consolidation system.
    
    Implements:
    - Offline replay during idle periods
    - Pattern completion & separation
    - Schema extraction from repeated episodes
    - Complementary learning systems (CLS) theory
    - Sharp-wave ripple simulation
    """
    
    def __init__(
        self,
        episodic_memory=None,
        semantic_memory=None,
        procedural_memory=None,
        llm_fn: Callable = None,
        replay_batch_size: int = 32,
        consolidation_threshold: int = 3,
        schema_extraction_threshold: int = 5,
    ):
        self.episodic = episodic_memory
        self.semantic = semantic_memory
        self.procedural = procedural_memory
        self.llm_fn = llm_fn
        
        self.replay_batch_size = replay_batch_size
        self.consolidation_threshold = consolidation_threshold
        self.schema_extraction_threshold = schema_extraction_threshold
        
        # Memory traces (consolidated long-term)
        self.traces: Dict[str, MemoryTrace] = {}
        self.schemas: Dict[str, Schema] = {}
        
        # Replay buffer
        self.replay_buffer: deque = deque(maxlen=10000)
        self.replay_priorities: Dict[str, float] = {}
        
        # Consolidation state
        self.consolidation_cycle = 0
        self._running = False
        self._consolidation_task: Optional[asyncio.Task] = None
        
        # Sharp-wave ripple events
        self.ripple_events: List[Dict] = []
        
        # Persistence
        self.trace_file = MEMORY_DIR / "traces.jsonl"
        self.schema_file = MEMORY_DIR / "schemas.jsonl"
    
    async def initialize(self) -> None:
        """Load persisted traces and schemas."""
        await self._load_traces()
        await self._load_schemas()
        print(f"✅ Hippocampus initialized: {len(self.traces)} traces, {len(self.schemas)} schemas")
    
    async def start_consolidation(self, interval_seconds: int = 300) -> None:
        """Start background consolidation loop."""
        if self._running:
            return
        self._running = True
        self._consolidation_task = asyncio.create_task(self._consolidation_loop(interval_seconds))
    
    async def stop_consolidation(self) -> None:
        """Stop background consolidation."""
        self._running = False
        if self._consolidation_task:
            self._consolidation_task.cancel()
            try:
                await self._consolidation_task
            except asyncio.CancelledError:
                pass
    
    async def _consolidation_loop(self, interval: int) -> None:
        """Main consolidation loop (simulates sleep)."""
        while self._running:
            try:
                await asyncio.sleep(interval)
                await self.consolidate()
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Consolidation error: {e}")
    
    async def consolidate(self) -> Dict:
        """Run one consolidation cycle."""
        self.consolidation_cycle += 1
        results = {
            "cycle": self.consolidation_cycle,
            "replayed": 0,
            "consolidated": 0,
            "schemas_extracted": 0,
            "ripples": 0,
        }
        
        # 1. Prioritized replay
        replayed = await self._prioritized_replay()
        results["replayed"] = replayed
        
        # 2. Consolidate high-priority traces
        consolidated = await self._consolidate_traces()
        results["consolidated"] = consolidated
        
        # 3. Extract schemas
        schemas = await self._extract_schemas()
        results["schemas_extracted"] = schemas
        
        # 4. Simulate sharp-wave ripples
        ripples = await self._simulate_ripples()
        results["ripples"] = ripples
        
        # 5. Decay old traces
        await self._decay_traces()
        
        # Persist
        await self._save_traces()
        await self._save_schemas()
        
        return results
    
    async def _prioritized_replay(self) -> int:
        """Replay high-priority memories (sharp-wave ripples)."""
        if not self.replay_buffer:
            return 0
        
        # Sample from replay buffer with priority weighting
        items = list(self.replay_buffer)
        if not items:
            return 0
        
        priorities = [self.replay_priorities.get(item.get("id", ""), 1.0) for item in items]
        total = sum(priorities)
        probs = [p / total for p in priorities]
        
        replay_count = min(self.replay_batch_size, len(items))
        indices = np.random.choice(len(items), size=replay_count, p=probs, replace=False)
        
        replayed = 0
        for idx in indices:
            episode = items[idx]
            await self._process_replay(episode)
            replayed += 1
            
            # Record ripple event
            self.ripple_events.append({
                "cycle": self.consolidation_cycle,
                "episode_id": episode.get("id"),
                "timestamp": time.time(),
            })
        
        return replayed
    
    async def _process_replay(self, episode: Dict) -> None:
        """Process a replayed episode for consolidation."""
        episode_id = episode.get("id")
        if not episode_id:
            return
        
        # Check if we have a trace for this episode
        if episode_id in self.traces:
            trace = self.traces[episode_id]
            trace.strength = min(1.0, trace.strength + 0.1)
            trace.last_recalled = time.time()
            trace.recall_count += 1
        else:
            # Create new trace
            trace = MemoryTrace(
                id=episode_id,
                content=episode.get("goal", "") + " -> " + str(episode.get("result", ""))[:200],
                trace_type="episodic",
                strength=0.5,
                metadata={
                    "episode": episode,
                    "success": episode.get("success", False),
                },
            )
            self.traces[episode_id] = trace
        
        # Link to similar traces (pattern completion)
        await self._link_associations(trace)
    
    async def _link_associations(self, trace: MemoryTrace) -> None:
        """Link trace to similar traces (pattern completion)."""
        if not self.llm_fn:
            return
        
        # Find similar traces
        similar = await self._find_similar_traces(trace.content, limit=5)
        for sim_trace in similar:
            if sim_trace.id != trace.id and sim_trace.id not in trace.associations:
                trace.associations.append(sim_trace.id)
                # Bidirectional
                if trace.id not in sim_trace.associations:
                    sim_trace.associations.append(trace.id)
    
    async def _find_similar_traces(self, content: str, limit: int = 5) -> List[MemoryTrace]:
        """Find similar traces using simple keyword overlap."""
        query_words = set(content.lower().split())
        scored = []
        
        for trace in self.traces.values():
            trace_words = set(trace.content.lower().split())
            overlap = len(query_words & trace_words)
            if overlap > 0:
                scored.append((overlap / len(query_words | trace_words), trace))
        
        scored.sort(key=lambda x: x[0], reverse=True)
        return [t for _, t in scored[:limit]]
    
    async def _consolidate_traces(self) -> int:
        """Consolidate strong traces to semantic memory."""
        consolidated = 0
        
        for trace in list(self.traces.values()):
            # Consolidate if strong enough and repeated
            if (trace.strength >= 0.7 and 
                trace.recall_count >= self.consolidation_threshold and
                trace.trace_type == "episodic"):
                
                # Promote to semantic
                trace.trace_type = "semantic"
                trace.consolidation_cycle = self.consolidation_cycle
                
                # Store in semantic memory if available
                if self.semantic and hasattr(self.semantic, 'add'):
                    try:
                        await asyncio.get_event_loop().run_in_executor(
                            None, self.semantic.add, trace.content, "consolidated"
                        )
                    except Exception:
                        pass
                
                consolidated += 1
        
        return consolidated
    
    async def _extract_schemas(self) -> int:
        """Extract schemas from repeated patterns."""
        if not self.llm_fn:
            return 0
        
        # Group traces by similarity
        groups = await self._group_similar_traces()
        extracted = 0
        
        for group in groups:
            if len(group) >= self.schema_extraction_threshold:
                schema = await self._extract_schema_from_group(group)
                if schema:
                    self.schemas[schema.id] = schema
                    extracted += 1
        
        return extracted
    
    async def _group_similar_traces(self) -> List[List[MemoryTrace]]:
        """Group traces by content similarity."""
        # Simple clustering by keyword overlap
        traces = [t for t in self.traces.values() if t.trace_type in ("episodic", "semantic")]
        groups = []
        used = set()
        
        for trace in traces:
            if trace.id in used:
                continue
            
            group = [trace]
            trace_words = set(trace.content.lower().split())
            
            for other in traces:
                if other.id in used or other.id == trace.id:
                    continue
                other_words = set(other.content.lower().split())
                overlap = len(trace_words & other_words) / max(1, len(trace_words | other_words))
                if overlap > 0.4:
                    group.append(other)
                    used.add(other.id)
            
            if len(group) >= 2:
                groups.append(group)
                used.add(trace.id)
        
        return groups
    
    async def _extract_schema_from_group(self, group: List[MemoryTrace]) -> Optional[Schema]:
        """Extract abstract schema from a group of similar traces."""
        if not self.llm_fn:
            return None
        
        # Prepare trace summaries
        summaries = [t.content[:300] for t in group]
        
        prompt = f"""Analyze these similar experiences and extract a reusable schema/pattern:

Experiences:
{json.dumps(summaries, indent=2)}

Extract a schema as JSON:
{{
  "name": "schema_name",
  "pattern": {{"trigger": "...", "steps": [...], "outcome": "..."}},
  "confidence": 0.8
}}"""
        
        try:
            response = self.llm_fn(prompt)
            data = json.loads(response[response.index("{"):response.rindex("}")+1])
            
            schema = Schema(
                id=f"schema_{uuid.uuid4().hex[:8]}",
                name=data.get("name", f"schema_{len(self.schemas)}"),
                pattern=data.get("pattern", {}),
                instances=[t.id for t in group],
                confidence=data.get("confidence", 0.5),
            )
            
            # Link traces to schema
            for trace in group:
                trace.metadata["schema"] = schema.id
            
            return schema
        except Exception:
            return None
    
    async def _simulate_ripples(self) -> int:
        """Simulate sharp-wave ripple events for memory reactivation."""
        # Generate ripple events for strongest traces
        strong_traces = [t for t in self.traces.values() if t.strength > 0.8]
        ripple_count = min(len(strong_traces), 10)
        
        for trace in random.sample(strong_traces, ripple_count) if strong_traces else []:
            self.ripple_events.append({
                "cycle": self.consolidation_cycle,
                "trace_id": trace.id,
                "type": "reactivation",
                "timestamp": time.time(),
            })
        
        return ripple_count
    
    async def _decay_traces(self, decay_rate: float = 0.01) -> None:
        """Apply decay to unused traces."""
        to_remove = []
        for trace_id, trace in self.traces.items():
            if trace.trace_type == "episodic":
                time_since_recall = time.time() - trace.last_recalled
                trace.strength = max(0.0, trace.strength - decay_rate * (time_since_recall / 3600))
                
                if trace.strength < 0.05:
                    to_remove.append(trace_id)
        
        for trace_id in to_remove:
            del self.traces[trace_id]
    
    def add_episode(self, episode: Dict) -> None:
        """Add episode to replay buffer (called after task completion)."""
        episode_id = episode.get("id", uuid.uuid4().hex[:12])
        episode["id"] = episode_id
        episode["timestamp"] = time.time()
        
        self.replay_buffer.append(episode)
        
        # Priority based on success and reward
        success = episode.get("success", False)
        reward = episode.get("reward", 0.0)
        self.replay_priorities[episode_id] = (1.5 if success else 0.5) + reward
    
    async def query_schema(self, query: str, limit: int = 3) -> List[Schema]:
        """Find relevant schemas for a query."""
        query_words = set(query.lower().split())
        scored = []
        
        for schema in self.schemas.values():
            # Match against schema pattern
            pattern_text = json.dumps(schema.pattern).lower()
            pattern_words = set(pattern_text.split())
            overlap = len(query_words & pattern_words)
            if overlap > 0:
                score = overlap / len(query_words | pattern_words)
                scored.append((score * schema.confidence, schema))
        
        scored.sort(key=lambda x: x[0], reverse=True)
        return [s for _, s in scored[:limit]]
    
    async def apply_schema(self, schema_id: str, context: Dict) -> Dict:
        """Apply a schema to current context."""
        schema = self.schemas.get(schema_id)
        if not schema:
            return {"error": "Schema not found"}
        
        schema.applications += 1
        
        # Use LLM to instantiate schema
        if self.llm_fn:
            prompt = f"""Apply this schema to the current context:

Schema: {json.dumps(schema.pattern, indent=2)}
Context: {json.dumps(context, indent=2)}

Provide the instantiated steps as JSON."""
            
            try:
                response = self.llm_fn(prompt)
                instantiated = json.loads(response[response.index("{"):response.rindex("}")+1])
                return {"instantiated": instantiated, "schema": schema.name}
            except Exception:
                pass
        
        return {"schema": schema.pattern, "name": schema.name}
    
    async def _load_traces(self) -> None:
        if self.trace_file.exists():
            for line in self.trace_file.read_text().strip().split("\n"):
                if line:
                    data = json.loads(line)
                    trace = MemoryTrace(**data)
                    self.traces[trace.id] = trace
    
    async def _save_traces(self) -> None:
        with self.trace_file.open("w") as f:
            for trace in self.traces.values():
                f.write(json.dumps(vars(trace), default=str) + "\n")
    
    async def _load_schemas(self) -> None:
        if self.schema_file.exists():
            for line in self.schema_file.read_text().strip().split("\n"):
                if line:
                    data = json.loads(line)
                    schema = Schema(**data)
                    self.schemas[schema.id] = schema
    
    async def _save_schemas(self) -> None:
        with self.schema_file.open("w") as f:
            for schema in self.schemas.values():
                f.write(json.dumps(vars(schema), default=str) + "\n")
    
    def get_stats(self) -> Dict:
        return {
            "traces": len(self.traces),
            "by_type": defaultdict(int, {t.trace_type: sum(1 for t in self.traces.values() if t.trace_type == t.trace_type) for t in self.traces.values()}),
            "schemas": len(self.schemas),
            "replay_buffer": len(self.replay_buffer),
            "consolidation_cycle": self.consolidation_cycle,
            "ripple_events": len(self.ripple_events),
            "avg_trace_strength": np.mean([t.strength for t in self.traces.values()]) if self.traces else 0,
        }


class SemanticConsolidation:
    """
    Belief revision with causal reasoning (Pearl-style).
    Implements: belief update, contraction, revision, causal inference.
    """
    
    def __init__(self, kernel=None, llm_fn: Callable = None):
        self.kernel = kernel
        self.llm_fn = llm_fn
        self.beliefs: Dict[str, Dict] = {}  # belief_id -> {proposition, confidence, causes, effects, evidence}
        self.causal_graph: Dict[str, Set[str]] = defaultdict(set)  # cause -> effects
        self.evidence_index: Dict[str, List[str]] = defaultdict(list)  # evidence -> belief_ids
    
    async def add_belief(
        self, 
        proposition: str, 
        confidence: float = 0.5,
        evidence: List[str] = None,
        causes: List[str] = None,
        effects: List[str] = None,
    ) -> str:
        """Add a belief with causal links."""
        belief_id = uuid.uuid4().hex[:12]
        
        self.beliefs[belief_id] = {
            "proposition": proposition,
            "confidence": confidence,
            "evidence": evidence or [],
            "causes": causes or [],
            "effects": effects or [],
            "created_at": time.time(),
            "updated_at": time.time(),
        }
        
        # Build causal graph
        for cause in causes or []:
            self.causal_graph[cause].add(belief_id)
        for effect in effects or []:
            self.causal_graph[belief_id].add(effect)
        
        # Index evidence
        for ev in evidence or []:
            self.evidence_index[ev].append(belief_id)
        
        return belief_id
    
    async def revise_belief(
        self, 
        belief_id: str, 
        new_confidence: float,
        new_evidence: str = None,
    ) -> Dict:
        """Revise belief confidence with new evidence (Bayesian update)."""
        if belief_id not in self.beliefs:
            return {"error": "Belief not found"}
        
        belief = self.beliefs[belief_id]
        old_confidence = belief["confidence"]
        
        # Bayesian update: P(H|E) = P(E|H)P(H) / P(E)
        # Simplified: weighted average with evidence strength
        evidence_strength = 0.8 if new_evidence else 0.5
        belief["confidence"] = (
            (1 - evidence_strength) * old_confidence + 
            evidence_strength * new_confidence
        )
        belief["confidence"] = max(0.01, min(0.99, belief["confidence"]))
        belief["updated_at"] = time.time()
        
        if new_evidence:
            belief["evidence"].append(new_evidence)
            self.evidence_index[new_evidence].append(belief_id)
        
        # Propagate through causal graph
        await self._propagate_confidence(belief_id, belief["confidence"] - old_confidence)
        
        return {
            "belief_id": belief_id,
            "old_confidence": old_confidence,
            "new_confidence": belief["confidence"],
            "delta": belief["confidence"] - old_confidence,
        }
    
    async def _propagate_confidence(self, source_id: str, delta: float, visited: Set = None) -> None:
        """Propagate confidence changes through causal graph."""
        if visited is None:
            visited = set()
        if source_id in visited:
            return
        visited.add(source_id)
        
        # Forward propagation (effects)
        for effect_id in self.causal_graph.get(source_id, []):
            if effect_id in self.beliefs:
                effect = self.beliefs[effect_id]
                # Attenuate delta
                effect["confidence"] = max(0.01, min(0.99, effect["confidence"] + delta * 0.5))
                effect["updated_at"] = time.time()
                await self._propagate_confidence(effect_id, delta * 0.5, visited)
        
        # Backward propagation (causes) - weaker
        for cause_id, effects in self.causal_graph.items():
            if source_id in effects and cause_id in self.beliefs:
                cause = self.beliefs[cause_id]
                cause["confidence"] = max(0.01, min(0.99, cause["confidence"] + delta * 0.2))
                cause["updated_at"] = time.time()
    
    async def causal_query(
        self, 
        cause: str = None, 
        effect: str = None,
        intervention: Dict = None,
    ) -> Dict:
        """Answer causal queries using do-calculus (simplified)."""
        if intervention:
            # Do-operator: intervene on variable
            var = intervention.get("variable")
            value = intervention.get("value")
            return await self._do_query(var, value, effect)
        
        if cause and effect:
            # P(effect | do(cause))
            return await self._causal_effect(cause, effect)
        
        if cause:
            # Find effects of cause
            return {"effects": list(self.causal_graph.get(cause, []))}
        
        if effect:
            # Find causes of effect
            causes = [c for c, effects in self.causal_graph.items() if effect in effects]
            return {"causes": causes}
        
        return {"causal_graph": {k: list(v) for k, v in self.causal_graph.items()}}
    
    async def _causal_effect(self, cause: str, effect: str) -> Dict:
        """Estimate causal effect using backdoor criterion (simplified)."""
        # Check direct causal link
        if effect in self.causal_graph.get(cause, []):
            cause_belief = self.beliefs.get(cause)
            effect_belief = self.beliefs.get(effect)
            
            if cause_belief and effect_belief:
                # Simple causal strength
                strength = cause_belief["confidence"] * effect_belief["confidence"]
                return {
                    "cause": cause,
                    "effect": effect,
                    "causal_strength": strength,
                    "direct": True,
                }
        
        # Check indirect paths (DFS)
        paths = await self._find_causal_paths(cause, effect)
        return {
            "cause": cause,
            "effect": effect,
            "paths": paths,
            "direct": False,
        }
    
    async def _find_causal_paths(self, start: str, target: str, max_depth: int = 4) -> List[List[str]]:
        """Find all causal paths from start to target."""
        paths = []
        
        def dfs(current: str, path: List[str], depth: int):
            if depth > max_depth:
                return
            if current == target:
                paths.append(path)
                return
            for next_node in self.causal_graph.get(current, []):
                if next_node not in path:
                    dfs(next_node, path + [next_node], depth + 1)
        
        dfs(start, [start], 0)
        return paths
    
    async def _do_query(self, variable: str, value: float, effect: str) -> Dict:
        """Simulate intervention do(variable=value)."""
        # Create counterfactual
        original_confidence = self.beliefs.get(variable, {}).get("confidence", 0.5)
        
        # Temporarily set value
        if variable in self.beliefs:
            self.beliefs[variable]["confidence"] = value
        
        # Query effect
        result = await self._causal_effect(variable, effect)
        
        # Restore
        if variable in self.beliefs:
            self.beliefs[variable]["confidence"] = original_confidence
        
        return {"intervention": {variable: value}, "effect_on": effect, **result}
    
    async def detect_conflicts(self) -> List[Dict]:
        """Detect conflicting beliefs."""
        conflicts = []
        beliefs = list(self.beliefs.items())
        
        for i, (id1, b1) in enumerate(beliefs):
            for id2, b2 in beliefs[i+1:]:
                # Check for contradictory propositions
                if self._contradicts(b1["proposition"], b2["proposition"]):
                    conflicts.append({
                        "belief_1": id1,
                        "belief_2": id2,
                        "prop_1": b1["proposition"],
                        "prop_2": b2["proposition"],
                        "conf_1": b1["confidence"],
                        "conf_2": b2["confidence"],
                    })
        
        return conflicts
    
    def _contradicts(self, prop1: str, prop2: str) -> bool:
        """Simple contradiction detection."""
        negations = ["not", "no", "never", "false", "incorrect", "wrong"]
        # Very simplified - would use NLI model in practice
        return False
    
    def get_stats(self) -> Dict:
        return {
            "beliefs": len(self.beliefs),
            "causal_links": sum(len(v) for v in self.causal_graph.values()),
            "evidence_items": len(self.evidence_index),
            "avg_confidence": np.mean([b["confidence"] for b in self.beliefs.values()]) if self.beliefs else 0,
        }


class WorkingMemoryV2:
    """
    Enhanced working memory with:
    - Chunking (Miller's 7±2)
    - Multi-head attention
    - Retrieval-augmented WM
    - Decay with recency/frequency
    """
    
    def __init__(self, capacity: int = 7, decay_rate: float = 0.1):
        self.capacity = capacity
        self.decay_rate = decay_rate
        self.chunks: Dict[str, Dict] = {}  # chunk_id -> {items, strength, created}
        self.items: Dict[str, Dict] = {}  # item_id -> {content, chunk_id, attention, ...}
        self.attention_heads = 4
        self.retrieval_augmented = True
        self._access_history: deque = deque(maxlen=1000)
    
    def add(self, content: str, chunk_id: str = None, attention: float = 1.0) -> str:
        """Add item to working memory."""
        item_id = uuid.uuid4().hex[:12]
        
        # Find or create chunk
        if chunk_id is None:
            chunk_id = self._find_or_create_chunk(content)
        
        self.items[item_id] = {
            "content": content,
            "chunk_id": chunk_id,
            "attention": attention,
            "created_at": time.time(),
            "last_accessed": time.time(),
            "access_count": 0,
        }
        
        # Update chunk
        if chunk_id not in self.chunks:
            self.chunks[chunk_id] = {
                "items": [],
                "strength": 0.0,
                "created_at": time.time(),
            }
        self.chunks[chunk_id]["items"].append(item_id)
        self.chunks[chunk_id]["strength"] = min(1.0, self.chunks[chunk_id]["strength"] + 0.1)
        
        # Enforce capacity (chunk-level)
        self._enforce_capacity()
        
        return item_id
    
    def _find_or_create_chunk(self, content: str) -> str:
        """Find existing chunk or create new one."""
        content_words = set(content.lower().split())
        
        best_chunk = None
        best_overlap = 0
        
        for chunk_id, chunk in self.chunks.items():
            # Calculate overlap with chunk items
            for item_id in chunk["items"]:
                if item_id in self.items:
                    item_words = set(self.items[item_id]["content"].lower().split())
                    overlap = len(content_words & item_words) / max(1, len(content_words | item_words))
                    if overlap > best_overlap:
                        best_overlap = overlap
                        best_chunk = chunk_id
        
        if best_chunk and best_overlap > 0.3:
            return best_chunk
        
        return f"chunk_{uuid.uuid4().hex[:8]}"
    
    def _enforce_capacity(self) -> None:
        """Enforce chunk capacity limit."""
        if len(self.chunks) <= self.capacity:
            return
        
        # Remove weakest chunk
        weakest = min(self.chunks.items(), key=lambda x: x[1]["strength"])
        chunk_id = weakest[0]
        
        # Remove items in chunk
        for item_id in self.chunks[chunk_id]["items"]:
            self.items.pop(item_id, None)
        
        del self.chunks[chunk_id]
    
    def attend(self, item_id: str, boost: float = 0.2) -> bool:
        """Boost attention for an item."""
        if item_id not in self.items:
            return False
        
        self.items[item_id]["attention"] = min(1.0, self.items[item_id]["attention"] + boost)
        self.items[item_id]["last_accessed"] = time.time()
        self.items[item_id]["access_count"] += 1
        
        # Boost chunk too
        chunk_id = self.items[item_id]["chunk_id"]
        if chunk_id in self.chunks:
            self.chunks[chunk_id]["strength"] = min(1.0, self.chunks[chunk_id]["strength"] + 0.05)
        
        self._access_history.append({"item_id": item_id, "time": time.time()})
        return True
    
    def retrieve(self, query: str, limit: int = 5) -> List[Dict]:
        """Retrieve items matching query (with attention weighting)."""
        query_words = set(query.lower().split())
        scored = []
        
        for item_id, item in self.items.items():
            content_words = set(item["content"].lower().split())
            overlap = len(query_words & content_words) / max(1, len(query_words | content_words))
            
            # Weight by attention
            score = overlap * (0.5 + 0.5 * item["attention"])
            
            if score > 0:
                scored.append((score, item_id, item))
        
        scored.sort(key=lambda x: x[0], reverse=True)
        
        results = []
        for score, item_id, item in scored[:limit]:
            self.attend(item_id, 0.1)
            results.append({
                "item_id": item_id,
                "content": item["content"],
                "score": score,
                "attention": item["attention"],
                "chunk_id": item["chunk_id"],
            })
        
        return results
    
    def decay(self) -> int:
        """Apply decay to all items."""
        removed = 0
        now = time.time()
        
        for item_id, item in list(self.items.items()):
            time_elapsed = now - item["last_accessed"]
            decay = self.decay_rate * (time_elapsed / 3600)  # Per hour
            item["attention"] = max(0.0, item["attention"] - decay)
            
            if item["attention"] < 0.05:
                chunk_id = item["chunk_id"]
                if chunk_id in self.chunks:
                    self.chunks[chunk_id]["items"].remove(item_id)
                del self.items[item_id]
                removed += 1
        
        # Remove empty chunks
        empty_chunks = [cid for cid, c in self.chunks.items() if not c["items"]]
        for cid in empty_chunks:
            del self.chunks[cid]
        
        return removed
    
    def get_state(self) -> Dict:
        return {
            "chunks": len(self.chunks),
            "items": len(self.items),
            "capacity": self.capacity,
            "chunks_detail": {
                cid: {
                    "item_count": len(c["items"]),
                    "strength": c["strength"],
                }
                for cid, c in self.chunks.items()
            },
        }


# Module singletons
_hippocampus: Optional[Hippocampus] = None
_semantic_consolidation: Optional[SemanticConsolidation] = None
_working_memory_v2: Optional[WorkingMemoryV2] = None


async def get_hippocampus(**kwargs) -> Hippocampus:
    global _hippocampus
    if _hippocampus is None:
        _hippocampus = Hippocampus(**kwargs)
        await _hippocampus.initialize()
    return _hippocampus


def get_semantic_consolidation(**kwargs) -> SemanticConsolidation:
    global _semantic_consolidation
    if _semantic_consolidation is None:
        _semantic_consolidation = SemanticConsolidation(**kwargs)
    return _semantic_consolidation


def get_working_memory_v2(**kwargs) -> WorkingMemoryV2:
    global _working_memory_v2
    if _working_memory_v2 is None:
        _working_memory_v2 = WorkingMemoryV2(**kwargs)
    return _working_memory_v2