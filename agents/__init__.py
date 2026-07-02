"""Maya 3.0 — Phase 4 Multi-Agent System.

Orchestrator + specialist agents on top of the Phase 3 brain.
Registry, permissions, messaging, health — all additive.
"""
from .base import BaseAgent
from .registry import AgentRegistry
from .messaging import MessageBus
from .roster import build_default_agents
from .orchestrator import Orchestrator
