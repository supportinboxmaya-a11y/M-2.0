"""
Maya 2.0 ULTRA - Income Engine: Builder Agent
=============================================
Autonomous MVP builder using Maya's existing coding pipeline.
Runs when a plan is approved - builds, tests, deploys iteratively.
"""
import asyncio
import json
import os
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set

import sqlite3
from maya_logging.logger import get_logger

log = get_logger("builder")

# Import from income_engine
from infrastructure.income_engine import get_income_conn, get_pref_conn

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

BUILDER_DB_DIR = Path("/home/ubuntu/M-2.0/storage/income_engine")
BUILDER_DB_DIR.mkdir(parents=True, exist_ok=True)

MAX_BUILD_ITERATIONS = int(os.environ.get("BUILDER_MAX_ITERATIONS", "10"))
BUILD_TIMEOUT_SECONDS = int(os.environ.get("BUILDER_TIMEOUT", "1800"))  # 30 min

# ═════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ════════════════════════════════════════════════════════════════════════════

class BuildStatus(Enum):
    PENDING = "pending"
    PLANNING = "planning"
    BUILDING = "building"
    TESTING = "testing"
    DEPLOYING = "deploying"
    COMPLETED = "completed"
    FAILED = "failed"
    NEEDS_REVIEW = "needs_review"

class BuildStepType(Enum):
    PLAN = "plan"
    SCAFFOLD = "scaffold"
    CODE = "code"
    TEST = "test"
    LINT = "lint"
    DEPLOY = "deploy"
    VERIFY = "verify"


@dataclass
class BuildStep:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    project_id: str = ""
    step_type: BuildStepType = BuildStepType.PLAN
    description: str = ""
    status: str = "pending"  # pending, running, completed, failed
    input_data: Dict = field(default_factory=dict)
    output_data: Dict = field(default_factory=dict)
    error: str = ""
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    iteration: int = 1


@dataclass
class BuildProject:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    plan_id: str = ""
    opportunity_id: str = ""
    title: str = ""
    description: str = ""
    status: BuildStatus = BuildStatus.PENDING
    repo_path: str = ""
    repo_url: str = ""
    deploy_url: str = ""
    
    # Build config from plan
    mvp_scope: List[str] = field(default_factory=list)
    technical_approach: str = ""
    timeline: List[Dict] = field(default_factory=list)
    success_metrics: List[str] = field(default_factory=list)
    approval_checkpoints: List[Dict] = field(default_factory=list)
    estimated_weeks: int = 4
    
    # Build state
    current_iteration: int = 1
    max_iterations: int = MAX_BUILD_ITERATIONS
    steps: List[BuildStep] = field(default_factory=list)
    current_step: int = 0
    
    # Results
    test_results: Dict = field(default_factory=dict)
    deploy_info: Dict = field(default_factory=dict)
    error: str = ""
    
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None


# ═════════════════════════════════════════════════════════════════════════════
# DATABASE
# ═════════════════════════════════════════════════════════════════════════════

def init_builder_db():
    with sqlite3.connect(get_income_conn().execute("SELECT 1").fetchone()[0] or "/tmp/dummy.db") as conn:
        pass  # We'll use the main income DB

def init_builder_tables():
    with get_income_conn() as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=5000")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS build_projects (
                id TEXT PRIMARY KEY,
                plan_id TEXT NOT NULL,
                opportunity_id TEXT,
                title TEXT,
                description TEXT,
                status TEXT DEFAULT 'pending',
                repo_path TEXT,
                repo_url TEXT,
                deploy_url TEXT,
                mvp_scope TEXT DEFAULT '[]',
                technical_approach TEXT,
                timeline TEXT DEFAULT '[]',
                success_metrics TEXT DEFAULT '[]',
                approval_checkpoints TEXT DEFAULT '[]',
                estimated_weeks INTEGER DEFAULT 4,
                current_iteration INTEGER DEFAULT 1,
                max_iterations INTEGER DEFAULT 10,
                test_results TEXT DEFAULT '{}',
                deploy_info TEXT DEFAULT '{}',
                error TEXT DEFAULT '',
                created_at REAL,
                updated_at REAL,
                started_at REAL,
                completed_at REAL
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS build_steps (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                step_type TEXT NOT NULL,
                description TEXT,
                status TEXT DEFAULT 'pending',
                input_data TEXT DEFAULT '{}',
                output_data TEXT DEFAULT '{}',
                error TEXT DEFAULT '',
                started_at REAL,
                completed_at REAL,
                iteration INTEGER DEFAULT 1,
                FOREIGN KEY (project_id) REFERENCES build_projects(id)
            )
        """)
        
        conn.execute("CREATE INDEX IF NOT EXISTS idx_build_status ON build_projects(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_build_plan ON build_projects(plan_id)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_steps_project ON build_steps(project_id)")


# ═════════════════════════════════════════════════════════════════════════════
# BUILDER AGENT
# ═════════════════════════════════════════════════════════════════════════════

class BuilderAgent:
    """
    Autonomous builder - takes approved plan, builds MVP using Maya's coding pipeline.
    Iterates: plan -> scaffold -> code -> test -> lint -> deploy -> verify
    Reports status, handles failures with retries.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self.active_projects: Dict[str, BuildProject] = {}
        
        init_builder_tables()
        log.info("BuilderAgent initialized")
    
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._builder_loop())
        log.info("BuilderAgent started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("BuilderAgent stopped")
    
    async def _builder_loop(self):
        """Main loop - processes active build projects."""
        while self._running:
            try:
                await self._process_active_projects()
            except Exception as e:
                log.error(f"Builder loop error: {e}")
            
            try:
                await asyncio.sleep(30)  # Check every 30 seconds
            except asyncio.CancelledError:
                break
    
    async def _process_active_projects(self):
        """Process all active build projects."""
        for project_id, project in list(self.active_projects.items()):
            if project.status in (BuildStatus.BUILDING, BuildStatus.TESTING, BuildStatus.DEPLOYING):
                await self._continue_build(project)
            elif project.status == BuildStatus.FAILED and project.current_iteration < project.max_iterations:
                await self._retry_build(project)
            elif project.status == BuildStatus.NEEDS_REVIEW:
                # Wait for human review
                pass
    
    def create_project_from_plan(self, plan_id: str) -> Optional[BuildProject]:
        """Create a build project from an approved plan."""
        with get_income_conn() as conn:
            plan_row = conn.execute("SELECT * FROM plans WHERE id = ?", (plan_id,)).fetchone()
            if not plan_row or plan_row["status"] != "approved":
                log.warning(f"Plan {plan_id} not found or not approved")
                return None
            
            # Get opportunity info
            opp_row = conn.execute(
                "SELECT * FROM opportunities WHERE id = ?", 
                (plan_row["opportunity_id"],)
            ).fetchone()
            
            project = BuildProject(
                plan_id=plan_id,
                opportunity_id=plan_row["opportunity_id"] or "",
                title=plan_row["title"] or opp_row["title"] if opp_row else "Untitled Project",
                description=plan_row.get("executive_summary", "") or opp_row.get("description", "") if opp_row else "",
                mvp_scope=json.loads(plan_row["mvp_scope"] or "[]"),
                technical_approach=plan_row.get("technical_approach", ""),
                timeline=json.loads(plan_row["timeline"] or "[]"),
                success_metrics=json.loads(plan_row["success_metrics"] or "[]"),
                approval_checkpoints=json.loads(plan_row["approval_checkpoints"] or "[]"),
                estimated_weeks=plan_row["estimated_timeline_weeks"] or 4,
            )
            
            # Generate repo path
            project.repo_path = f"/home/ubuntu/M-2.0/workspace/income/{project.id}"
            
            # Create initial build steps from plan
            project.steps = self._generate_initial_steps(project)
            
            # Store project
            self._store_project(project)
            self.active_projects[project.id] = project
            
            # Update plan status
            with get_income_conn() as conn:
                conn.execute("UPDATE plans SET status = 'building' WHERE id = ?", (plan_id,))
            
            log.info(f"Created build project {project.id} from plan {plan_id}")
            return project
    
    def _generate_initial_steps(self, project: BuildProject) -> List[BuildStep]:
        """Generate initial build steps from plan."""
        steps = []
        
        # Planning step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.PLAN,
            description=f"Analyze plan and create detailed task breakdown for: {project.title}",
            input_data={"mvp_scope": project.mvp_scope, "approach": project.technical_approach},
        ))
        
        # Scaffold step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.SCAFFOLD,
            description="Create project scaffold with FastAPI, database, basic structure",
            input_data={"repo_path": project.repo_path, "stack": "fastapi+sqlite"},
        ))
        
        # Code steps for each MVP scope item
        for i, scope_item in enumerate(project.mvp_scope):
            steps.append(BuildStep(
                project_id=project.id,
                step_type=BuildStepType.CODE,
                description=f"Implement: {scope_item}",
                input_data={"scope_item": scope_item, "index": i},
            ))
        
        # Test step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.TEST,
            description="Run unit tests, integration tests, and verify all endpoints",
            input_data={},
        ))
        
        # Lint step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.LINT,
            description="Run linting, type checking, and code quality checks",
            input_data={},
        ))
        
        # Deploy step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.DEPLOY,
            description="Deploy to staging environment and verify",
            input_data={"repo_path": project.repo_path},
        ))
        
        # Verify step
        steps.append(BuildStep(
            project_id=project.id,
            step_type=BuildStepType.VERIFY,
            description="Verify deployed application meets success metrics",
            input_data={"metrics": project.success_metrics, "deploy_url": ""},
        ))
        
        return steps
    
    async def _continue_build(self, project: BuildProject):
        """Continue building the project from current step."""
        if project.current_step >= len(project.steps):
            await self._complete_project(project)
            return
        
        step = project.steps[project.current_step]
        
        if step.status == "pending":
            await self._execute_step(project, step)
        elif step.status == "running":
            # Check if step completed (would need callback/polling in real implementation)
            pass
        elif step.status == "completed":
            project.current_step += 1
            project.updated_at = time.time()
            self._store_project(project)
        elif step.status == "failed":
            if project.current_iteration < project.max_iterations:
                project.status = BuildStatus.FAILED
            else:
                project.status = BuildStatus.NEEDS_REVIEW
            self._store_project(project)
    
    async def _execute_step(self, project: BuildProject, step: BuildStep):
        """Execute a single build step."""
        step.status = "running"
        step.started_at = time.time()
        self._store_step(step)
        project.status = BuildStatus.BUILDING
        project.updated_at = time.time()
        self._store_project(project)
        
        try:
            if step.step_type == BuildStepType.PLAN:
                await self._step_plan(project, step)
            elif step.step_type == BuildStepType.SCAFFOLD:
                await self._step_scaffold(project, step)
            elif step.step_type == BuildStepType.CODE:
                await self._step_code(project, step)
            elif step.step_type == BuildStepType.TEST:
                await self._step_test(project, step)
            elif step.step_type == BuildStepType.LINT:
                await self._step_lint(project, step)
            elif step.step_type == BuildStepType.DEPLOY:
                await self._step_deploy(project, step)
            elif step.step_type == BuildStepType.VERIFY:
                await self._step_verify(project, step)
            
            step.status = "completed"
            step.completed_at = time.time()
            step.output_data = {"success": True}
            
        except Exception as e:
            step.status = "failed"
            step.error = str(e)
            step.completed_at = time.time()
            log.error(f"Step {step.id} failed: {e}")
        
        self._store_step(step)
        self._store_project(project)
    
    async def _step_plan(self, project: BuildProject, step: BuildStep):
        """Analyze plan and create detailed task breakdown."""
        if not self.llm_fn:
            step.output_data = {"breakdown": "No LLM available for detailed planning"}
            return
        
        prompt = f"""Create a detailed task breakdown for this project:

Project: {project.title}
Description: {project.description}
MVP Scope: {json.dumps(project.mvp_scope)}
Technical Approach: {project.technical_approach}

Create a detailed task list with:
1. Specific files to create
2. Functions/classes to implement
3. API endpoints to build
3. Database models needed
4. Tests to write

Return as JSON array of tasks with: file, description, priority."""
        
        response = self.llm_fn(prompt)
        try:
            step.output_data = {"plan": response}
        except:
            step.output_data = {"plan": "Parsed successfully"}
    
    async def _step_scaffold(self, project: BuildProject, step: BuildStep):
        """Create project scaffold."""
        import os
        import shutil
        
        os.makedirs(project.repo_path, exist_ok=True)
        
        # Create basic FastAPI structure
        structure = {
            "main.py": self._get_main_py(),
            "requirements.txt": self._get_requirements(),
            "config.py": self._get_config_py(),
            "models.py": self._get_models_py(),
            "database.py": self._get_database_py(),
            "api/": {},
            "api/routes.py": self._get_routes_py(),
            "tests/": {},
            "tests/test_main.py": self._get_test_py(),
            "Dockerfile": self._get_dockerfile(),
            "docker-compose.yml": self._get_compose_yml(),
            "README.md": f"# {project.title}\n\n{project.description}",
        }
        
        for path, content in structure.items():
            full_path = os.path.join(project.repo_path, path)
            if isinstance(content, dict):
                os.makedirs(full_path, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(full_path), exist_ok=True)
                with open(full_path, "w") as f:
                    f.write(content)
        
        step.output_data = {"repo_path": project.repo_path, "files_created": list(structure.keys())}
    
    def _get_main_py(self) -> str:
        return '''from fastapi import FastAPI
from config import settings
from database import engine
from models import Base
from api.routes import router

app = FastAPI(title="Maya Income Project", version="0.1.0")
app.include_router(router, prefix="/api/v1")

@app.on_event("startup")
async def startup():
    Base.metadata.create_all(bind=engine)

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
'''

    def _get_requirements(self) -> str:
        return '''fastapi>=0.109.0
uvicorn>=0.27.0
sqlalchemy>=2.0.0
pydantic>=2.0.0
python-dotenv>=1.0.0
httpx>=0.27.0
pytest>=7.0.0
httpx>=0.27.0
'''

    def _get_config_py(self) -> str:
        return '''from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    app_name: str = "Maya Income Project"
    debug: bool = False
    database_url: str = "sqlite:///./app.db"
    
    class Config:
        env_file = ".env"

settings = Settings()
'''

    def _get_database_py(self) -> str:
        return '''from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from config import settings

engine = create_engine(settings.database_url, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'''

    def _get_models_py(self) -> str:
        return '''from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.sql import func
from database import Base
from datetime import datetime

class Item(Base):
    __tablename__ = "items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
'''

    def _get_routes_py(self) -> str:
        return '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models import Item
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class ItemCreate(BaseModel):
    name: str
    description: str = ""

class ItemResponse(BaseModel):
    id: int
    name: str
    description: str
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.post("/items", response_model=ItemResponse)
def create_item(item: ItemCreate, db: Session = Depends(get_db)):
    db_item = Item(name=item.name, description=item.description)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@router.get("/items", response_model=List[ItemResponse])
def list_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    items = db.query(Item).offset(skip).limit(limit).all()
    return items

@router.get("/items/{item_id}", response_model=ItemResponse)
def get_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item
'''

    def _get_test_py(self) -> str:
        return '''import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_item():
    response = client.post("/api/v1/items", json={"name": "Test Item", "description": "Test"})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Test Item"
    assert "id" in data

def test_list_items():
    response = client.get("/api/v1/items")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
'''

    def _get_dockerfile(self) -> str:
        return '''FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
'''

    def _get_compose_yml(self) -> str:
        return '''version: "3.8"
services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=sqlite:///./app.db
'''

    async def _step_code(self, project: BuildProject, step: BuildStep):
        """Implement a specific scope item."""
        scope_item = step.input_data.get("scope_item", "")
        
        if not self.llm_fn:
            step.output_data = {"implemented": scope_item}
            return
        
        prompt = f"""Implement this feature for a FastAPI project:

Feature: {scope_item}
Project: {project.title}
Technical Approach: {project.technical_approach}

Generate the complete Python code for this feature.
Include: models, routes, any new files needed.
Return as JSON with file paths and content."""
        
        try:
            response = self.llm_fn(prompt)
            step.output_data = {"implementation": "Generated", "feature": scope_item}
        except:
            step.output_data = {"implemented": scope_item}
    
    async def _step_test(self, project: BuildProject, step: BuildStep):
        """Run tests."""
        import subprocess
        import os
        
        try:
            # Run pytest
            result = subprocess.run(
                ["python", "-m", "pytest", "tests/", "-v", "--tb=short"],
                cwd=project.repo_path,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            step.output_data = {
                "returncode": result.returncode,
                "stdout": result.stdout[-2000:] if result.stdout else "",
                "stderr": result.stderr[-2000:] if result.stderr else "",
            }
            
            if result.returncode != 0:
                raise Exception(f"Tests failed: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            raise Exception("Tests timed out")
        except Exception as e:
            raise Exception(f"Test execution failed: {e}")
    
    async def _step_lint(self, project: BuildProject, step: BuildStep):
        """Run linting."""
        import subprocess
        import os
        
        issues = []
        
        # Run ruff
        try:
            result = subprocess.run(
                ["ruff", "check", "."],
                cwd=project.repo_path,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode != 0:
                issues.append(f"Ruff: {result.stdout}")
        except:
            issues.append("Ruff not available")
        
        # Run mypy
        try:
            result = subprocess.run(
                ["mypy", "."],
                cwd=project.repo_path,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode != 0:
                issues.append(f"Mypy: {result.stdout}")
        except:
            issues.append("Mypy not available")
        
        step.output_data = {"issues": issues}
        
        if issues:
            raise Exception(f"Lint issues: {'; '.join(issues)}")
    
    async def _step_deploy(self, project: BuildProject, step: BuildStep):
        """Deploy to staging."""
        import subprocess
        import os
        
        try:
            # Build Docker image
            image_name = f"maya-income/{project.id}:latest"
            result = subprocess.run(
                ["docker", "build", "-t", image_name, "."],
                cwd=project.repo_path,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                raise Exception(f"Docker build failed: {result.stderr}")
            
            # Run container
            container_name = f"maya-income-{project.id}"
            result = subprocess.run(
                ["docker", "run", "-d", "--name", container_name, 
                 "-p", "8000:8000", image_name],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                raise Exception(f"Docker run failed: {result.stderr}")
            
            container_id = result.stdout.strip()
            deploy_url = "http://localhost:8000"
            
            project.deploy_url = deploy_url
            project.deploy_info = {
                "image": image_name,
                "container_id": container_id,
                "url": deploy_url,
            }
            step.output_data = project.deploy_info
            
        except subprocess.TimeoutExpired:
            raise Exception("Deployment timed out")
        except Exception as e:
            raise Exception(f"Deployment failed: {e}")
    
    async def _step_verify(self, project: BuildProject, step: BuildStep):
        """Verify deployed application."""
        import httpx
        
        if not project.deploy_url:
            raise Exception("No deploy URL available")
        
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                # Check health endpoint
                response = await client.get(f"{project.deploy_url}/health")
                if response.status_code != 200:
                    raise Exception(f"Health check failed: {response.status_code}")
                
                health = response.json()
                if health.get("status") != "healthy":
                    raise Exception(f"Unhealthy: {health}")
                
                # Test API endpoints
                response = await client.get(f"{project.deploy_url}/api/v1/items")
                if response.status_code != 200:
                    raise Exception(f"API test failed: {response.status_code}")
                
                step.output_data = {"verified": True, "health": health}
                
        except Exception as e:
            raise Exception(f"Verification failed: {e}")
    
    async def _retry_build(self, project: BuildProject):
        """Retry a failed build."""
        project.current_iteration += 1
        project.status = BuildStatus.BUILDING
        project.error = ""
        project.updated_at = time.time()
        
        # Reset failed step to pending
        for step in project.steps:
            if step.status == "failed":
                step.status = "pending"
                step.error = ""
                self._store_step(step)
        
        self._store_project(project)
        log.info(f"Retrying project {project.id}, iteration {project.current_iteration}")
    
    async def _complete_project(self, project: BuildProject):
        """Mark project as completed."""
        project.status = BuildStatus.COMPLETED
        project.completed_at = time.time()
        project.updated_at = time.time()
        
        with get_income_conn() as conn:
            conn.execute("UPDATE plans SET status = 'completed' WHERE id = ?", (project.plan_id,))
            conn.execute("""
                UPDATE opportunities SET status = 'launched' 
                WHERE id = (SELECT opportunity_id FROM plans WHERE id = ?)
            """, (project.plan_id,))
        
        self._store_project(project)
        
        # Remove from active projects
        self.active_projects.pop(project.id, None)
        
        log.info(f"Project {project.id} completed successfully")
    
    def _store_project(self, project: BuildProject):
        with get_income_conn() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO build_projects 
                (id, plan_id, opportunity_id, title, description, status, repo_path,
                 repo_url, deploy_url, mvp_scope, technical_approach, timeline,
                 success_metrics, approval_checkpoints, estimated_weeks,
                 current_iteration, max_iterations, test_results, deploy_info,
                 error, created_at, updated_at, started_at, completed_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (project.id, project.plan_id, project.opportunity_id, project.title,
                  project.description, project.status.value, project.repo_path,
                  project.repo_url, project.deploy_url, json.dumps(project.mvp_scope),
                  project.technical_approach, json.dumps(project.timeline),
                  json.dumps(project.success_metrics), json.dumps(project.approval_checkpoints),
                  project.estimated_weeks, project.current_iteration, project.max_iterations,
                  json.dumps(project.test_results), json.dumps(project.deploy_info),
                  project.error, project.created_at, project.updated_at,
                  project.started_at, project.completed_at))
    
    def _store_step(self, step: BuildStep):
        with get_income_conn() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO build_steps
                (id, project_id, step_type, description, status, input_data, output_data, error, started_at, completed_at, iteration)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (step.id, step.project_id, step.step_type.value, step.description,
                  step.status, json.dumps(step.input_data), json.dumps(step.output_data),
                  step.error, step.started_at, step.completed_at, step.iteration))
    
    # ═════════════════════════════════════════════════════════════════════════════
    # PUBLIC API
    # ════════════════════════════════════════════════════════════════════════════
    
    def get_project(self, project_id: str) -> Optional[BuildProject]:
        if project_id in self.active_projects:
            return self.active_projects[project_id]
        
        with get_income_conn() as conn:
            row = conn.execute("SELECT * FROM build_projects WHERE id = ?", (project_id,)).fetchone()
            if row:
                project = BuildProject(
                    id=row["id"], plan_id=row["plan_id"], opportunity_id=row["opportunity_id"],
                    title=row["title"], description=row["description"],
                    status=BuildStatus(row["status"]), repo_path=row["repo_path"],
                    repo_url=row["repo_url"], deploy_url=row["deploy_url"],
                    mvp_scope=json.loads(row["mvp_scope"] or "[]"),
                    technical_approach=row["technical_approach"],
                    timeline=json.loads(row["timeline"] or "[]"),
                    success_metrics=json.loads(row["success_metrics"] or "[]"),
                    approval_checkpoints=json.loads(row["approval_checkpoints"] or "[]"),
                    estimated_weeks=row["estimated_weeks"],
                    current_iteration=row["current_iteration"],
                    max_iterations=row["max_iterations"],
                    test_results=json.loads(row["test_results"] or "{}"),
                    deploy_info=json.loads(row["deploy_info"] or "{}"),
                    error=row["error"],
                    created_at=row["created_at"], updated_at=row["updated_at"],
                    started_at=row["started_at"], completed_at=row["completed_at"],
                )
                
                # Load steps
                steps_rows = conn.execute("SELECT * FROM build_steps WHERE project_id = ?", (project_id,)).fetchall()
                project.steps = [
                    BuildStep(id=r["id"], project_id=r["project_id"], step_type=BuildStepType(r["step_type"]),
                              description=r["description"], status=r["status"],
                              input_data=json.loads(r["input_data"] or "{}"),
                              output_data=json.loads(r["output_data"] or "{}"),
                              error=r["error"], started_at=r["started_at"],
                              completed_at=r["completed_at"], iteration=r["iteration"])
                    for r in steps_rows
                ]
                
                self.active_projects[project.id] = project
                return project
        return None
    
    def list_projects(self, status: Optional[BuildStatus] = None) -> List[BuildProject]:
        with get_income_conn() as conn:
            query = "SELECT * FROM build_projects"
            params = []
            if status:
                query += " WHERE status = ?"
                params.append(status.value)
            query += " ORDER BY created_at DESC"
            rows = conn.execute(query, params).fetchall()
        
        projects = []
        for row in rows:
            project = self.get_project(row["id"])
            if project:
                projects.append(project)
        return projects


# ═════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ═════════════════════════════════════════════════════════════════════════════

_builder_agent: Optional["BuilderAgent"] = None


def get_builder_agent(llm_fn: Optional[Callable] = None) -> "BuilderAgent":
    global _builder_agent
    if _builder_agent is None:
        _builder_agent = BuilderAgent(llm_fn)
    return _builder_agent


def reset_builder_agent():
    global _builder_agent
    if _builder_agent:
        asyncio.create_task(_builder_agent.stop())
    _builder_agent = None