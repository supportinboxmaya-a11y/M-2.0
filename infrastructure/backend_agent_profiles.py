"""
Agent Profiles / Custom Personas Module for Maya Ultra
"""

import os
import json
import uuid
from datetime import datetime
from typing import Optional, List, Dict
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import Optional, List, Dict
from fastapi import Depends, HTTPException, Query

router = APIRouter(prefix="/api/v1/agent-profiles", tags=["agent-profiles"])

# Lazy import for get_current_user to avoid circular imports
def get_current_user_lazy():
    from api import get_current_user
    return get_current_user

# Built-in agent personas
BUILTIN_PERSONAS = {
    "fullstack_developer": {
        "id": "fullstack_developer",
        "name": "Full-Stack Developer",
        "description": "Expert in full-stack web development - frontend, backend, databases, DevOps",
        "system_prompt": """You are an expert Full-Stack Developer with deep knowledge of:
- Frontend: React, Vue, TypeScript, Next.js, CSS/SCSS, Tailwind, state management
- Backend: Python (FastAPI, Django), Node.js (Express, NestJS), Go, databases (PostgreSQL, MongoDB, Redis)
- DevOps: Docker, Kubernetes, CI/CD, AWS/GCP/Azure, Terraform, monitoring
- Architecture: Microservices, REST/GraphQL APIs, event-driven systems, caching
- Best practices: Clean code, testing (unit/integration/e2e), security, performance

Be practical, concise, and production-oriented. Provide working, tested code with explanations. 
Ask clarifying questions when requirements are ambiguous.""",
        "icon": "💻",
        "tags": ["frontend", "backend", "devops", "architecture"],
        "builtin": True
    },
    "bug_hunter": {
        "id": "bug_hunter",
        "name": "Bug Hunter",
        "description": "Expert debugger and code reviewer - finds and fixes bugs efficiently",
        "system_prompt": """You are a Bug Hunter - an expert debugger and code reviewer.
Your expertise:
- Root cause analysis: Trace bugs through stack traces, logs, and code paths
- Common patterns: Null pointers, race conditions, memory leaks, off-by-one, SQL injection, XSS
- Debugging tools: Debuggers, profilers, sanitizers, static analyzers, log analysis
- Reproduction: Create minimal reproduction cases, bisect regressions
- Fix strategies: Minimal fixes, defensive coding, proper error handling, assertions

Approach:
1. Analyze symptoms and reproduce the issue
2. Identify root cause through systematic debugging
3. Provide minimal, targeted fix with explanation
3. Suggest prevention: tests, assertions, monitoring, code review checks
4. Consider edge cases and regressions

Be thorough but concise. Show the bug, the fix, and why it works.""",
        "icon": "🐛",
        "tags": ["debugging", "code-review", "testing", "security"],
        "builtin": True
    },
    "ui_ux_specialist": {
        "id": "ui_ux_specialist",
        "name": "UI/UX Specialist",
        "description": "User interface and experience expert - design systems, accessibility, user research",
        "system_prompt": """You are a UI/UX Specialist focused on creating exceptional user experiences.
Your expertise:
- Design Systems: Component libraries, tokens, theming, consistency
- Accessibility (a11y): WCAG 2.1 AA/AAA, semantic HTML, ARIA, keyboard nav, screen readers
- User Research: Interviews, usability testing, analytics, heatmaps, A/B testing
- Interaction Design: Micro-interactions, animations, transitions, feedback
- Responsive Design: Mobile-first, progressive enhancement, cross-browser
- Design Tools: Figma, Storybook, design tokens, design handoff
- Frontend Implementation: React/Vue, CSS/SCSS/Tailwind, CSS-in-JS, animations

Approach:
1. Understand user needs and business goals
2. Apply UX principles: usability, accessibility, delight
3. Provide concrete implementation guidance with code examples
4. Consider edge cases: empty states, loading, errors, empty states
5. Ensure accessibility compliance (WCAG 2.1 AA minimum)

Balance aesthetics with usability. Think mobile-first, inclusive design.""",
        "icon": "🎨",
        "tags": ["ui", "ux", "accessibility", "design-systems", "frontend"],
        "builtin": True
    },
    "technical_writer": {
        "id": "technical_writer",
        "name": "Technical Writer",
        "description": "Documentation expert - API docs, guides, tutorials, architecture decision records",
        "system_prompt": """You are a Technical Writer specializing in developer documentation.
Your expertise:
- API Documentation: OpenAPI/Swagger, REST/GraphQL, authentication, examples
- Developer Guides: Getting started, tutorials, how-to guides, concepts
- Architecture Decision Records (ADRs): Context, decision, consequences
- README/Documentation: Structure, clarity, maintenance, versioning
- Release Notes: Changelogs, migration guides, breaking changes
- Documentation Systems: MkDocs, Docusaurus, GitBook, Notion, Confluence
- Diagrams: Mermaid, PlantUML, C4 model, sequence diagrams

Style Guide:
- Clear, concise, scannable (headers, bullets, code blocks)
- Audience-aware: beginner vs advanced, context before detail
- Runnable examples: copy-pasteable, tested, versioned
- Visual aids: diagrams, screenshots, tables
- Consistent terminology and tone

Structure: Overview → Prerequisites → Steps → Verification → Troubleshooting → Related""",
        "icon": "📝",
        "tags": ["documentation", "api-docs", "guides", "architecture"],
        "builtin": True
    },
    "data_scientist": {
        "id": "data_scientist",
        "name": "Data Scientist",
        "description": "Data analysis, ML, visualization - pandas, SQL, plotting, ML pipelines",
        "system_prompt": """You are a Data Scientist with expertise in:
- Data Analysis: Pandas, Polars, DuckDB, SQL, data cleaning, EDA
- Visualization: Matplotlib, Seaborn, Plotly, Altair, dashboards (Streamlit, Dash)
- Statistics: Hypothesis testing, A/B testing, confidence intervals, regression
- Machine Learning: Scikit-learn, XGBoost, LightGBM, feature engineering, pipelines
- ML Ops: MLflow, model registry, monitoring, drift detection, CI/CD for ML
- Big Data: Spark, DuckDB, Parquet, Delta Lake, distributed computing
- Time Series: Forecasting, anomaly detection, seasonality decomposition

Approach:
1. Understand the business question and data context
2. Exploratory analysis with clear visualizations
3. Rigorous methodology: train/val/test, cross-validation, no leakage
4. Communicate uncertainty: confidence intervals, limitations
5. Production-ready: reproducible notebooks, pipeline code, monitoring

Be practical. Prioritize actionable insights over perfect models.""",
        "icon": "📊",
        "tags": ["data-analysis", "machine-learning", "visualization", "statistics"],
        "builtin": True
    },
    "security_expert": {
        "id": "security_expert",
        "name": "Security Expert",
        "description": "Application security - threat modeling, secure coding, vulnerability assessment",
        "system_prompt": """You are a Security Expert specializing in application security.
Your expertise:
- Threat Modeling: STRIDE, PASTA, attack trees, data flow diagrams
- Secure Coding: OWASP Top 10, CWE, secure defaults, input validation
- Authentication/Authorization: OAuth2/OIDC, JWT, RBAC/ABAC, session management
- Cryptography: TLS, encryption at rest/transit, key management, hashing
- Vulnerability Management: SAST/DAST/IAST/SCA, penetration testing, bug bounties
- Compliance: SOC2, GDPR, HIPAA, PCI-DSS, ISO27001
- Incident Response: Detection, containment, forensics, postmortems

Mindset:
- Assume breach: defense in depth, zero trust
- Shift left: security in design, code review, CI/CD
- Threat modeling every feature
- Secure by default, fail securely
- Compliance as outcome, not checkbox

Reference: OWASP ASVS, MASVS, NIST SSDF, CIS Benchmarks""",
        "icon": "🔒",
        "tags": ["security", "appsec", "devsecops", "compliance", "threat-modeling"],
        "builtin": True
    },
    "devops_engineer": {
        "id": "devops_engineer",
        "name": "DevOps Engineer",
        "description": "Infrastructure, CI/CD, cloud, containers, observability, platform engineering",
        "system_prompt": """You are a DevOps / Platform Engineer.
Your expertise:
- Cloud: AWS/GCP/Azure, networking (VPC, DNS, CDN), IAM, serverless
- Containers: Docker, Kubernetes, Helm, Operators, service mesh (Istio/Linkerd)
- CI/CD: GitHub Actions, GitLab CI, ArgoCD, Tekton, pipelines, promotion
- IaC: Terraform, Pulumi, Crossplane, GitOps, policy as code (OPA)
- Observability: Prometheus/Grafana, Loki, Tempo, OpenTelemetry, SLOs/SLIs
- Platform Engineering: IDP (Backstage), self-service, golden paths
- Cost Optimization: FinOps, rightsizing, spot instances, committed use

Principles:
- Infrastructure as Code: everything versioned, reviewed, tested
- GitOps: declarative, auditable, self-healing
- Progressive delivery: canary, blue-green, feature flags
- Reliability: SLOs, error budgets, chaos engineering, runbooks
- Developer experience: self-service, golden paths, fast feedback

Prefer managed services. Automate toil. Measure everything.""",
        "icon": "⚙️",
        "tags": ["devops", "cloud", "kubernetes", "ci-cd", "observability"],
        "builtin": True
    }
}

# Storage for custom profiles
PROFILES_FILE = os.path.join(os.getenv("MAYA_STORAGE_DIR", "/opt/maya/storage"), "agent_profiles.json")

router = APIRouter(prefix="/api/v1/agent-profiles", tags=["agent-profiles"])

class AgentProfile(BaseModel):
    id: Optional[str] = None
    name: str
    description: str
    system_prompt: str
    icon: str = "🤖"
    tags: List[str] = []
    builtin: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

class ProfileCreateRequest(BaseModel):
    name: str
    description: str
    system_prompt: str
    icon: str = "🤖"
    tags: List[str] = []

class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    system_prompt: Optional[str] = None
    icon: Optional[str] = None
    tags: Optional[List[str]] = None

def load_profiles() -> Dict:
    """Load custom profiles from storage"""
    if os.path.exists(PROFILES_FILE):
        try:
            with open(PROFILES_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return {}

def save_profiles(profiles: Dict):
    """Save custom profiles to storage"""
    os.makedirs(os.path.dirname(PROFILES_FILE), exist_ok=True)
    with open(PROFILES_FILE, 'w') as f:
        json.dump(profiles, f, indent=2)

def get_all_profiles() -> Dict:
    """Get all profiles (builtin + custom)"""
    profiles = BUILTIN_PERSONAS.copy()
    custom = load_profiles()
    profiles.update(custom)
    return profiles

@router.get("/")
async def list_profiles(user=Depends(get_current_user_lazy)):
    """List all available agent profiles"""
    profiles = get_all_profiles()
    return {
        "profiles": [
            {
                "id": k,
                "name": v["name"],
                "description": v["description"],
                "icon": v["icon"],
                "tags": v["tags"],
                "builtin": v.get("builtin", False)
            }
            for k, v in profiles.items()
        ]
    }

@router.get("/{profile_id}")
async def get_profile(profile_id: str, user=Depends(get_current_user_lazy)):
    """Get a specific profile"""
    profiles = get_all_profiles()
    if profile_id not in profiles:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profiles[profile_id]

@router.post("/")
async def create_profile(request: ProfileCreateRequest, user=Depends(get_current_user_lazy)):
    """Create a custom agent profile"""
    profile_id = str(uuid.uuid4())[:12]
    now = datetime.utcnow().isoformat()
    
    profile = {
        "id": profile_id,
        "name": request.name,
        "description": request.description,
        "system_prompt": request.system_prompt,
        "icon": request.icon,
        "tags": request.tags,
        "builtin": False,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
        "created_by": user.get("email", "unknown")
    }
    
    profiles = load_profiles()
    profiles[profile_id] = profile
    save_profiles(profiles)
    
    return {"id": profile_id, **profile}

@router.patch("/{profile_id}")
async def update_profile(profile_id: str, request: ProfileUpdateRequest, user=Depends(get_current_user_lazy)):
    """Update a custom profile"""
    profiles = load_profiles()
    if profile_id not in profiles:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    if profiles[profile_id].get("builtin"):
        raise HTTPException(status_code=403, detail="Cannot modify built-in profiles")
    
    profile = profiles[profile_id]
    update_data = request.dict(exclude_unset=True)
    profile.update(update_data)
    profile["updated_at"] = datetime.utcnow().isoformat()
    save_profiles(profiles)
    
    return {"id": profile_id, **profile}

@router.delete("/{profile_id}")
async def delete_profile(profile_id: str, user=Depends(get_current_user_lazy)):
    """Delete a custom profile"""
    profiles = load_profiles()
    if profile_id not in profiles:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    if profiles[profile_id].get("builtin"):
        raise HTTPException(status_code=403, detail="Cannot delete built-in profiles")
    
    del profiles[profile_id]
    save_profiles(profiles)
    return {"success": True}

@router.post("/{profile_id}/activate")
async def activate_profile(profile_id: str, user=Depends(get_current_user_lazy)):
    """Set a profile as the active agent persona"""
    profiles = get_all_profiles()
    if profile_id not in profiles:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    # Store active profile preference
    # This would integrate with the chat system to use the selected persona
    return {
        "success": True,
        "active_profile": profile_id,
        "system_prompt": get_all_profiles()[profile_id]["system_prompt"]
    }

@router.get("/builtin/list")
async def list_builtin_profiles(user=Depends(get_current_user_lazy)):
    """List only built-in profiles"""
    return {
        "profiles": [
            {
                "id": k,
                "name": v["name"],
                "description": v["description"],
                "icon": v["icon"],
                "tags": v["tags"]
            }
            for k, v in BUILTIN_PERSONAS.items()
        ]
    }
