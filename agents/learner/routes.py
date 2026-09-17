from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from agents.learner.config import LearnerConfig
from agents.learner.learner_agent import MayaLearner
from agents.learner.knowledge_persister import KnowledgePersister


router = APIRouter(prefix="/api/v1/learner", tags=["learner"])
_learner: Optional[MayaLearner] = None
_knowledge: Optional[KnowledgePersister] = None


def get_learner() -> MayaLearner:
    global _learner
    if _learner is None:
        if not LearnerConfig.ENABLED:
            raise HTTPException(503, "Learner disabled. Set LEARNER_ENABLED=true")
        _learner = MayaLearner()
    return _learner


def get_knowledge() -> KnowledgePersister:
    global _knowledge
    if _knowledge is None:
        _knowledge = KnowledgePersister()
    return _knowledge


class LearnRequest(BaseModel):
    goal: str
    missing_capability: str


class LearnResponse(BaseModel):
    task_id: str
    status: str
    skill_id: Optional[str] = None
    error: Optional[str] = None


@router.post("/learn", response_model=LearnResponse)
async def learn_capability(req: LearnRequest, learner: MayaLearner = Depends(get_learner)):
    """Trigger autonomous learning for a missing capability."""
    task = await learner.learn_capability(req.goal, req.missing_capability)
    return LearnResponse(
        task_id=task.id,
        status=task.status,
        skill_id=task.skill_id,
        error=task.error,
    )


@router.get("/tasks/{task_id}")
async def get_task(task_id: str, learner: MayaLearner = Depends(get_learner)):
    task = await learner.get_task_status(task_id)
    if not task:
        # Check persisted records
        knowledge = get_knowledge()
        record = knowledge.get_record(task_id)
        if not record:
            raise HTTPException(404, "Task not found")
        return {
            "id": record.id,
            "goal": record.goal,
            "capability": record.missing_capability,
            "status": record.status,
            "skill_id": record.skill_id,
            "error": record.error,
            "created_at": record.created_at.isoformat(),
            "completed_at": record.completed_at.isoformat() if record.completed_at else None,
        }
    return {
        "id": task.id,
        "goal": task.goal,
        "capability": task.missing_capability,
        "status": task.status,
        "skill_id": task.skill_id,
        "error": task.error,
        "created_at": task.created_at.isoformat(),
    }


@router.get("/tasks")
async def list_tasks(
    status: Optional[str] = None,
    limit: int = 50,
    learner: MayaLearner = Depends(get_learner),
):
    tasks = await learner.list_tasks(status, limit)
    return {
        "tasks": [
            {
                "id": t.id,
                "goal": t.goal,
                "capability": t.missing_capability,
                "status": t.status,
                "skill_id": t.skill_id,
                "error": t.error,
                "created_at": t.created_at.isoformat(),
            }
            for t in tasks
        ],
        "count": len(tasks),
    }


@router.get("/skills")
async def list_skills(
    capability_type: Optional[str] = None,
    limit: int = 50,
    knowledge: KnowledgePersister = Depends(get_knowledge),
):
    skills = knowledge.list_skills(limit, capability_type)
    return {
        "skills": [
            {
                "id": s.id,
                "name": s.name,
                "description": s.description,
                "capability_type": s.capability_type,
                "success_rate": s.success_rate,
                "usage_count": s.usage_count,
                "source_urls": s.source_urls,
                "created_at": s.created_at.isoformat(),
            }
            for s in skills
        ],
        "count": len(skills),
    }


@router.get("/skills/{skill_id}")
async def get_skill(skill_id: str, knowledge: KnowledgePersister = Depends(get_knowledge)):
    skill = knowledge.get_skill(skill_id)
    if not skill:
        raise HTTPException(404, "Skill not found")
    return {
        "id": skill.id,
        "name": skill.name,
        "description": skill.description,
        "capability_type": skill.capability_type,
        "code": skill.code,
        "input_schema": skill.input_schema,
        "output_schema": skill.output_schema,
        "success_rate": skill.success_rate,
        "usage_count": skill.usage_count,
        "source_urls": skill.source_urls,
        "created_at": skill.created_at.isoformat(),
        "updated_at": skill.updated_at.isoformat(),
    }


@router.get("/records")
async def list_records(
    capability: Optional[str] = None,
    limit: int = 20,
    knowledge: KnowledgePersister = Depends(get_knowledge),
):
    if capability:
        records = knowledge.get_records_by_capability(capability, limit)
    else:
        records = knowledge.get_recent_records(limit)
    return {
        "records": [
            {
                "id": r.id,
                "goal": r.goal,
                "capability": r.missing_capability,
                "status": r.status,
                "skill_id": r.skill_id,
                "error": r.error,
                "created_at": r.created_at.isoformat(),
                "completed_at": r.completed_at.isoformat() if r.completed_at else None,
            }
            for r in records
        ],
        "count": len(records),
    }


@router.get("/stats")
async def learner_stats(
    learner: MayaLearner = Depends(get_learner),
    knowledge: KnowledgePersister = Depends(get_knowledge),
):
    learner_stats = await learner.get_stats()
    skills = knowledge.list_skills()
    records = knowledge.get_recent_records(200)

    return {
        "enabled": LearnerConfig.ENABLED,
        "models": {"search": LearnerConfig.SEARCH_MODEL, "exec": LearnerConfig.EXEC_MODEL},
        "total_skills": len(skills),
        "total_learning_tasks": learner_stats.get("total_learning_tasks", 0),
        "completed_tasks": sum(1 for r in records if r.status == "done"),
        "failed_tasks": sum(1 for r in records if r.status == "failed"),
        "in_progress_tasks": sum(1 for r in records if r.status in ("pending", "searching", "scraping", "synthesizing", "executing", "distilling")),
        "skill_types": list(set(s.capability_type for s in skills if s.capability_type)),
    }


@router.get("/status")
async def learner_status():
    return {
        "enabled": LearnerConfig.ENABLED,
        "search_model": LearnerConfig.SEARCH_MODEL,
        "exec_model": LearnerConfig.EXEC_MODEL,
        "max_search_results": LearnerConfig.MAX_SEARCH_RESULTS,
        "max_scrape_length": LearnerConfig.MAX_SCRAPE_LENGTH,
        "sandbox_timeout": LearnerConfig.SANDBOX_TIMEOUT,
        "crawl_delay": LearnerConfig.CRAWL_DELAY,
        "auto_distill": LearnerConfig.AUTO_DISTILL,
        "require_approval": LearnerConfig.REQUIRE_APPROVAL,
    }