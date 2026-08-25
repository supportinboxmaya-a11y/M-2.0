#!/usr/bin/env python3
"""
Maya 2.0 ULTRA - Stress Test Suite
==================================

Comprehensive stress tests for long-horizon, ambiguous, multi-step, 
unfamiliar tasks with real LLM execution.

Run with: GROQ_KEY=your_key python3 stress_test.py --real
Run with mock: python3 stress_test.py --mock
"""
import sys
import os
import json
import asyncio
import time
import traceback
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent))

from core.planner import Planner
from core.executor import Executor
from core.verifier import Verifier
from core.task_manager import TaskManager
from core.fallback_manager import FallbackManager
from core.workflow_engine import WorkflowEngine
from memory.memory_manager import MemoryManager
from learning.improvement_engine import ImprovementEngine
from tools.tool_manager import ToolManager
from human.approval import ApprovalManager
from llm.router import LLMRouter


@dataclass
class StressTestResult:
    """Result of a stress test."""
    task_name: str
    goal: str
    success: bool
    attempts: int
    total_steps: int
    tools_used: List[str]
    duration_seconds: float
    quality_score: float
    error: Optional[str] = None
    traceback_str: Optional[str] = None


@dataclass
class StressTestSuite:
    """Collection of stress tests."""
    results: List[StressTestResult] = field(default_factory=list)
    start_time: float = field(default_factory=time.time)
    
    def add_result(self, result: StressTestResult):
        self.results.append(result)
    
    def summary(self) -> Dict:
        total = len(self.results)
        passed = sum(1 for r in self.results if r.success)
        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "success_rate": passed / total * 100 if total else 0,
            "avg_attempts": sum(r.attempts for r in self.results) / total if total else 0,
            "avg_steps": sum(r.total_steps for r in self.results) / total if total else 0,
            "avg_duration": sum(r.duration_seconds for r in self.results) / total if total else 0,
            "total_duration": time.time() - self.start_time,
        }


class StressTestRunner:
    """Runs stress tests with configurable LLM backend."""
    
    def __init__(self, use_real_llm: bool = False, router: Optional[LLMRouter] = None):
        self.use_real_llm = use_real_llm
        self.router = router
        self.suite = StressTestSuite()
        
        # Initialize components
        self.tool_manager = ToolManager()
        self.memory = MemoryManager()
        self.planner = None
        self.executor = None
        self.verifier = None
        self.task_mgr = TaskManager()
        self.fallback = None
        self.learning = None
        self.approval = ApprovalManager(mode='skip')
        self.workflow = None
        self._init_components()
    
    def _init_components(self):
        """Initialize all Maya components."""
        if self.use_real_llm:
            if not self.router:
                self.router = LLMRouter()
            # Verify at least one provider is available
            available = self.router.available_providers()
            if not available:
                raise RuntimeError("No LLM providers available! Set API keys in .env")
            print(f"Using real LLM with providers: {available}")
        else:
            self.router = self._create_mock_router()
            print("Using mock LLM router")
        
        self.planner = Planner(self.router)
        self.executor = Executor(self.router, self.tool_manager.get_registry())
        self.verifier = Verifier(self.router)
        self.fallback = FallbackManager(self.planner, self.router)
        self.learning = ImprovementEngine(self.router)
        
        self.workflow = WorkflowEngine(
            planner=self.planner,
            executor=self.executor,
            verifier=self.verifier,
            task_manager=self.task_mgr,
            fallback_manager=self.fallback,
            memory_manager=self.memory,
            learning_engine=self.learning,
        )
    
    def _create_mock_router(self) -> LLMRouter:
        """Create a mock router for testing without API keys."""
        # We'll create a mock inline
        class MockRouter:
            def __init__(self):
                self.call_count = 0
            
            def chat(self, messages, provider=None, model=None, max_tokens=4000, task_type="general"):
                self.call_count += 1
                msg_str = str(messages).lower()
                
                # Planning phase
                if 'planning' in msg_str or ('plan' in msg_str and 'verify' not in msg_str and 'explanation' not in msg_str):
                    import json
                    return json.dumps(self._generate_plan(messages))
                
                # Verification phase
                if 'verify' in msg_str or 'verification' in msg_str:
                    import json
                    return json.dumps(self._get_verification_result())
                
                # Learning phase
                if 'learn' in msg_str or 'lesson' in msg_str:
                    import json
                    return json.dumps(self._get_learning_result())
                
                return 'Mock response'
            
            def stream_chat(self, messages, **kwargs):
                yield self.chat(messages)
            
            def _generate_plan(self, messages):
                goal = ""
                for m in messages:
                    if m.get('role') == 'user':
                        goal = m.get('content', '')
                        break
                return self._plan_for_goal(goal)
            
            def _plan_for_goal(self, goal):
                goal_lower = goal.lower()
                
                if 'weather' in goal_lower and 'api' in goal_lower:
                    return {
                        "goal_analysis": "Create weather fetching tool using OpenWeatherMap API",
                        "complexity": "medium",
                        "approach": "Write Python module with weather fetching function, test it",
                        "estimated_steps": 3,
                        "steps": [
                            {"step": 1, "title": "Create weather module", "description": "Write Python module with OpenWeatherMap API integration", "tool": "write_file", "tool_input": {"filename": "weather_tool.py", "content": "import os\nimport requests\n\ndef get_weather(city: str, api_key: str = None) -> dict:\n    key = api_key or os.environ.get('OPENWEATHER_API_KEY')\n    if not key:\n        return {'error': 'No API key provided'}\n    url = 'https://api.openweathermap.org/data/2.5/weather'\n    params = {'q': city, 'appid': key, 'units': 'metric'}\n    try:\n        response = requests.get(url, params=params, timeout=10)\n        response.raise_for_status()\n        data = response.json()\n        return {'city': data['name'], 'temperature': data['main']['temp'], 'description': data['weather'][0]['description'], 'humidity': data['main']['humidity']}\n    except Exception as e:\n        return {'error': str(e)}\n\nif __name__ == '__main__':\n    print('Weather tool ready. Provide API key to fetch real data.')\n    print('Usage: get_weather(\"London\", \"your_api_key\")')"}, "expected_output": "File created", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Test weather module", "description": "Run the module to verify it loads correctly", "tool": "run_code", "tool_input": {"code": "import weather_tool\nprint('Module loaded successfully')\nprint('Function available:', hasattr(weather_tool, 'get_weather'))"}, "expected_output": "Module loads successfully", "on_failure": "retry", "depends_on": [1]},
                            {"step": 3, "title": "Verify function signature", "description": "Check the function works with mock input", "tool": "run_code", "tool_input": {"code": "import weather_tool\nimport inspect\nsig = inspect.signature(weather_tool.get_weather)\nprint('Signature:', sig)\nprint('Parameters:', list(sig.parameters.keys()))"}, "expected_output": "Function signature verified", "on_failure": "retry", "depends_on": [1]}
                        ],
                        "success_criteria": "Weather module created, loads, and has correct function signature",
                        "risks": ["Requires API key for real data"]
                    }
                
                elif 'csv' in goal_lower or 'excel' in goal_lower or 'spreadsheet' in goal_lower:
                    return {
                        "goal_analysis": "Process CSV/Excel data: read, filter, write results",
                        "complexity": "low",
                        "approach": "Write script that reads CSV, filters data, writes output",
                        "estimated_steps": 3,
                        "steps": [
                            {"step": 1, "title": "Create sample data", "description": "Generate CSV file with sample data", "tool": "write_file", "tool_input": {"filename": "sample_data.csv", "content": "name,age,city,salary\nAlice,30,New York,75000\nBob,25,San Francisco,85000\nCharlie,35,Chicago,65000\nDiana,28,Boston,70000\nEve,32,Seattle,80000"}, "expected_output": "CSV file created", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Process CSV data", "description": "Read CSV, filter high earners, write results", "tool": "run_code", "tool_input": {"code": "import csv\nwith open('sample_data.csv', 'r') as f:\n    reader = csv.DictReader(f)\n    rows = list(reader)\nhigh_earners = [r for r in rows if int(r['salary']) > 70000]\nprint(f'Total: {len(rows)}, High earners: {len(high_earners)}')\nfor r in high_earners:\n    print(f\"  {r['name']}: ${r['salary']} in {r['city']}\")\nwith open('high_earners.csv', 'w', newline='') as f:\n    writer = csv.DictWriter(f, fieldnames=rows[0].keys())\n    writer.writeheader()\n    writer.writerows(high_earners)"}, "expected_output": "Filtered data printed and written to file", "on_failure": "retry", "depends_on": [1]},
                            {"step": 3, "title": "Verify output", "description": "Read back the filtered CSV to verify", "tool": "run_code", "tool_input": {"code": "import csv\nwith open('high_earners.csv', 'r') as f:\n    reader = csv.DictReader(f)\n    for row in reader:\n        print(row)"}, "expected_output": "Output file verified", "on_failure": "retry", "depends_on": [2]}
                        ],
                        "success_criteria": "CSV processed, filtered, and verified",
                        "risks": []
                    }
                
                elif 'docker' in goal_lower or 'container' in goal_lower:
                    return {
                        "goal_analysis": "Create Flask app with Dockerfile for containerization",
                        "complexity": "medium",
                        "approach": "Create Flask app, Dockerfile, and build script",
                        "estimated_steps": 4,
                        "steps": [
                            {"step": 1, "title": "Create Flask app", "description": "Write simple Flask web application", "tool": "write_file", "tool_input": {"filename": "app.py", "content": "from flask import Flask, jsonify\nimport os\n\napp = Flask(__name__)\n\n@app.route('/')\ndef hello():\n    return jsonify({'message': 'Hello from Maya!', 'version': '1.0', 'container': os.environ.get('HOSTNAME', 'local')})\n\n@app.route('/health')\ndef health():\n    return jsonify({'status': 'healthy'})\n\nif __name__ == '__main__':\n    app.run(host='0.0.0.0', port=5000)"}, "expected_output": "Flask app created", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Create requirements.txt", "description": "Define Python dependencies", "tool": "write_file", "tool_input": {"filename": "requirements.txt", "content": "flask==3.0.0"}, "expected_output": "Requirements file created", "on_failure": "retry", "depends_on": []},
                            {"step": 3, "title": "Create Dockerfile", "description": "Write Dockerfile for the Flask app", "tool": "write_file", "tool_input": {"filename": "Dockerfile", "content": "FROM python:3.11-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY app.py .\nEXPOSE 5000\nCMD [\"python\", \"app.py\"]"}, "expected_output": "Dockerfile created", "on_failure": "retry", "depends_on": [1, 2]},
                            {"step": 4, "title": "Validate Dockerfile syntax", "description": "Check Dockerfile can be parsed", "tool": "run_shell", "tool_input": {"command": "docker build --dry-run -t test-app . 2>&1 || echo 'Dry run not supported, checking syntax...' && cat Dockerfile"}, "expected_output": "Dockerfile syntax checked", "on_failure": "retry", "depends_on": [3]}
                        ],
                        "success_criteria": "Flask app, requirements, and Dockerfile created and validated",
                        "risks": ["Docker not available in test environment"]
                    }
                
                elif 'api' in goal_lower and 'rest' in goal_lower:
                    return {
                        "goal_analysis": "Create REST API client for a public API",
                        "complexity": "low",
                        "approach": "Write Python module with REST API client using requests",
                        "estimated_steps": 2,
                        "steps": [
                            {"step": 1, "title": "Create API client", "description": "Write REST client for JSONPlaceholder API", "tool": "write_file", "tool_input": {"filename": "api_client.py", "content": "import requests\nfrom typing import Dict, List, Optional\n\nclass JSONPlaceholderClient:\n    BASE_URL = 'https://jsonplaceholder.typicode.com'\n    def __init__(self, timeout: int = 10):\n        self.timeout = timeout\n        self.session = requests.Session()\n    def get_posts(self) -> List[Dict]:\n        response = self.session.get(f'{self.BASE_URL}/posts', timeout=self.timeout)\n        response.raise_for_status()\n        return response.json()\n    def get_post(self, post_id: int) -> Dict:\n        response = self.session.get(f'{self.BASE_URL}/posts/{post_id}', timeout=self.timeout)\n        response.raise_for_status()\n        return response.json()\n    def create_post(self, title: str, body: str, user_id: int) -> Dict:\n        response = self.session.post(f'{self.BASE_URL}/posts', json={'title': title, 'body': body, 'userId': user_id}, timeout=self.timeout)\n        response.raise_for_status()\n        return response.json()\n\nif __name__ == '__main__':\n    client = JSONPlaceholderClient()\n    posts = client.get_posts()\n    print(f'Fetched {len(posts)} posts')\n    print(f'First post: {posts[0][\"title\"]}')"}, "expected_output": "API client created", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Test API client", "description": "Run the client to fetch real data from the API", "tool": "run_code", "tool_input": {"code": "import api_client\nclient = api_client.JSONPlaceholderClient()\nposts = client.get_posts()\nprint(f'Successfully fetched {len(posts)} posts')\nprint(f'First post title: {posts[0][\"title\"]}')\nprint(f'Post keys: {list(posts[0].keys())}')"}, "expected_output": "Real API data fetched and displayed", "on_failure": "retry", "depends_on": [1]}
                        ],
                        "success_criteria": "API client created and successfully fetches real data",
                        "risks": ["Network connectivity required"]
                    }
                
                elif 'analyze' in goal_lower or 'report' in goal_lower:
                    return {
                        "goal_analysis": "Analyze data and generate a report",
                        "complexity": "low",
                        "approach": "Create sample data, analyze it, generate markdown report",
                        "estimated_steps": 3,
                        "steps": [
                            {"step": 1, "title": "Create dataset", "description": "Generate sample sales data", "tool": "write_file", "tool_input": {"filename": "sales_data.json", "content": "[\n  {\"product\": \"Widget A\", \"sales\": 150, \"revenue\": 7500, \"region\": \"North\"},\n  {\"product\": \"Widget B\", \"sales\": 200, \"revenue\": 12000, \"region\": \"South\"},\n  {\"product\": \"Widget C\", \"sales\": 75, \"revenue\": 5250, \"region\": \"East\"},\n  {\"product\": \"Widget D\", \"sales\": 300, \"revenue\": 18000, \"region\": \"West\"},\n  {\"product\": \"Widget E\", \"sales\": 120, \"revenue\": 7200, \"region\": \"North\"}\n]"}, "expected_output": "Sales data file created", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Analyze data", "description": "Compute statistics and generate insights", "tool": "run_code", "tool_input": {"code": "import json\nwith open('sales_data.json') as f:\n    data = json.load(f)\ntotal_sales = sum(d['sales'] for d in data)\ntotal_revenue = sum(d['revenue'] for d in data)\navg_price = total_revenue / total_sales if total_sales else 0\nby_region = {}\nfor d in data:\n    r = d['region']\n    if r not in by_region:\n        by_region[r] = {'sales': 0, 'revenue': 0}\n    by_region[r]['sales'] += d['sales']\n    by_region[r]['revenue'] += d['revenue']\nbest_product = max(data, key=lambda x: x['revenue'])\nworst_product = min(data, key=lambda x: x['revenue'])\nprint('=== SALES ANALYSIS REPORT ===')\nprint(f'Total Products: {len(data)}')\nprint(f'Total Units Sold: {total_sales}')\nprint(f'Total Revenue: ${total_revenue:,.2f}')\nprint(f'Average Price: ${avg_price:.2f}')\nprint(f'Best Product: {best_product[\"product\"]} (${best_product[\"revenue\"]:,.2f})')\nprint(f'Worst Product: {worst_product[\"product\"]} (${worst_product[\"revenue\"]:,.2f})')\nprint()\nprint('By Region:')\nfor region, stats in by_region.items():\n    print(f'  {region}: {stats[\"sales\"]} units, ${stats[\"revenue\"]:,.2f}')"}, "expected_output": "Analysis printed with statistics", "on_failure": "retry", "depends_on": [1]},
                            {"step": 3, "title": "Generate markdown report", "description": "Create formatted markdown report", "tool": "write_file", "tool_input": {"filename": "sales_report.md", "content": "# Sales Analysis Report\n\n## Summary\n- **Total Products:** 5\n- **Total Units Sold:** 845\n- **Total Revenue:** $50,950.00\n- **Average Price:** $60.30\n\n## Top Performer\n- **Widget D**: 300 units, $18,000.00\n\n## Lowest Performer\n- **Widget C**: 75 units, $5,250.00\n\n## Regional Breakdown\n| Region | Units | Revenue |\n|--------|-------|---------|\n| North  | 270   | $14,700 |\n| South  | 200   | $12,000 |\n| East   | 75    | $5,250  |\n| West   | 300   | $18,000 |\n\n## Recommendations\n1. Investigate Widget C's low performance\n2. Replicate Widget D's success in other regions\n3. Consider expanding West region inventory"}, "expected_output": "Markdown report created", "on_failure": "retry", "depends_on": [2]}
                        ],
                        "success_criteria": "Data analyzed and markdown report generated",
                        "risks": []
                    }
                
                elif 'research' in goal_lower or 'investigate' in goal_lower:
                    return {
                        "goal_analysis": "Research a topic and create a summary report",
                        "complexity": "medium",
                        "approach": "Use web search and scraping to gather information, then synthesize",
                        "estimated_steps": 4,
                        "steps": [
                            {"step": 1, "title": "Search for information", "description": "Search web for topic", "tool": "web_search", "tool_input": {"query": "latest developments in AI agents 2024", "max_results": 5}, "expected_output": "Search results", "on_failure": "retry", "depends_on": []},
                            {"step": 2, "title": "Scrape top results", "description": "Get content from top search results", "tool": "web_scrape", "tool_input": {"url": "https://example.com"}, "expected_output": "Page content", "on_failure": "retry", "depends_on": [1]},
                            {"step": 3, "title": "Synthesize findings", "description": "Create summary from gathered information", "tool": "run_code", "tool_input": {"code": "print('Research synthesis would go here')"}, "expected_output": "Synthesized report", "on_failure": "retry", "depends_on": [2]},
                            {"step": 4, "title": "Save report", "description": "Write research report to file", "tool": "write_file", "tool_input": {"filename": "research_report.md", "content": "# Research Report\n\n## Summary\nThis is a placeholder research report."}, "expected_output": "Report file created", "on_failure": "retry", "depends_on": [3]}
                        ],
                        "success_criteria": "Research conducted and report generated",
                        "risks": ["Web search requires API key", "Scraping may be blocked"]
                    }
                
                # Default plan
                return {
                    "goal_analysis": goal,
                    "complexity": "low",
                    "approach": "Direct execution",
                    "estimated_steps": 1,
                    "steps": [{"step": 1, "title": "Execute Goal", "description": goal, "tool": "run_code", "tool_input": {"code": f"print('Executing: {goal}')"}, "expected_output": "Goal executed", "on_failure": "retry", "depends_on": []}],
                    "success_criteria": "Goal completed",
                    "risks": []
                }
            
            def _get_verification_result(self):
                return {
                    "success": True, "verdict": "success", "quality_score": 8,
                    "completeness_percentage": 90, "what_was_achieved": "Goal completed successfully",
                    "what_is_missing": "", "errors_found": [], "reasoning": "All steps executed and verified",
                    "next_action": "done", "retry_hint": ""
                }
            
            def _get_learning_result(self):
                return {
                    "lesson": "Task completed using appropriate tools and patterns",
                    "pattern": "general_execution", "success_factors": ["Proper tool selection", "Step dependency management"],
                    "failure_factors": [], "future_tip": "Follow established patterns for similar tasks",
                    "tool_insights": "Tools work well together when properly chained", "estimated_difficulty": "easy",
                    "tags": ["execution", "tools"]
                }
            
            def secondary_provider(self, exclude=None): return 'mock'
            def best_provider(self, task_type='general'): return 'mock'
            def available_providers(self): return ['mock']
            def list_providers(self): return [{'id': 'mock', 'label': 'Mock', 'configured': True, 'enabled': True, 'active': True}]
            def set_enabled(self, provider, enabled): return True
            def set_key(self, provider, key): return True
        
        return MockRouter()
    
    def run_stress_test(self, task_name: str, goal: str, max_retries: int = 2) -> StressTestResult:
        """Run a single stress test."""
        print(f"\n{'='*60}")
        print(f"STRESS TEST: {task_name}")
        print(f"GOAL: {goal[:100]}...")
        print(f"{'='*60}")
        
        start_time = time.time()
        
        try:
            result = self.workflow.run(goal, max_retries=max_retries)
            
            duration = time.time() - start_time
            
            test_result = StressTestResult(
                task_name=task_name,
                goal=goal,
                success=result.get('success', False),
                attempts=result.get('attempts', 1),
                total_steps=len(result.get('steps', [])),
                tools_used=result.get('tools_used', []),
                duration_seconds=duration,
                quality_score=result.get('quality_score', 0),
                error=result.get('error') if not result.get('success') else None,
            )
            
            status = "PASS" if test_result.success else "FAIL"
            print(f"Result: {status} | Attempts: {test_result.attempts} | Steps: {test_result.total_steps} | Quality: {test_result.quality_score} | Duration: {duration:.1f}s")
            
            if test_result.error:
                print(f"Error: {test_result.error}")
            
            return test_result
            
        except Exception as e:
            duration = time.time() - start_time
            error_msg = str(e)
            tb = traceback.format_exc()
            
            test_result = StressTestResult(
                task_name=task_name,
                goal=goal,
                success=False,
                attempts=1,
                total_steps=0,
                tools_used=[],
                duration_seconds=duration,
                quality_score=0,
                error=error_msg,
                traceback_str=tb,
            )
            
            print(f"Result: FAIL (Exception) | Duration: {duration:.1f}s")
            print(f"Error: {error_msg}")
            
            return test_result
    
    def run_suite(self, tasks: List[Dict[str, str]], max_retries: int = 2) -> StressTestSuite:
        """Run a suite of stress tests."""
        print(f"\n{'#'*60}")
        print(f"# MAYA STRESS TEST SUITE")
        print(f"# Mode: {'REAL LLM' if self.use_real_llm else 'MOCK'}")
        print(f"# Tasks: {len(tasks)}")
        print(f"{'#'*60}")
        
        for task in tasks:
            result = self.run_stress_test(task['name'], task['goal'], max_retries)
            self.suite.add_result(result)
            
            # Small delay between tests
            time.sleep(1)
        
        return self.suite


# Stress test tasks - long-horizon, ambiguous, multi-step, unfamiliar
STRESS_TASKS = [
    {
        "name": "Weather API Tool Creation",
        "goal": "Create a Python module that fetches weather data from OpenWeatherMap API with a get_weather(city, api_key) function that handles errors gracefully and returns structured data"
    },
    {
        "name": "CSV Data Processing Pipeline",
        "goal": "Process a CSV file: read sample_data.csv, filter rows where salary > 70000, compute average salary by city, write results to high_earners.csv and summary.json"
    },
    {
        "name": "Flask Web App with Docker",
        "goal": "Create a simple Flask web application with a Dockerfile for containerization, including requirements.txt and health check endpoint"
    },
    {
        "name": "REST API Client with Real Data",
        "goal": "Build a REST API client for JSONPlaceholder that can fetch posts, create new posts, and update existing posts with proper error handling"
    },
    {
        "name": "Data Analysis & Report Generation",
        "goal": "Analyze sales data from sales_data.json and generate a markdown report with statistics, regional breakdown, and actionable recommendations"
    },
    {
        "name": "Multi-Step Research Task",
        "goal": "Research the topic 'autonomous AI agents' by searching the web, scraping relevant pages, and creating a comprehensive markdown report with citations"
    },
    {
        "name": "Git Repository Analysis",
        "goal": "Analyze the current git repository: get commit history, find most changed files, identify contributors, and generate a markdown summary report"
    },
    {
        "name": "SQLite Database Operations",
        "goal": "Create a SQLite database with tables for users and orders, insert sample data, run queries to find top customers by order value, and export results to CSV"
    },
    {
        "name": "File System Organization",
        "goal": "Organize the workspace directory: list all files, categorize by extension, create subdirectories for each type, move files accordingly, and generate a manifest"
    },
    {
        "name": "Complex Multi-Tool Workflow",
        "goal": "Create a Python script that: 1) fetches data from a public API, 2) processes and filters it, 3) saves to CSV and JSON, 4) generates a summary report, 5) creates a simple visualization data file"
    },
]


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Maya Stress Test Suite")
    parser.add_argument('--real', action='store_true', help='Use real LLM (requires API keys in .env)')
    parser.add_argument('--mock', action='store_true', help='Use mock LLM (default)')
    parser.add_argument('--tasks', type=int, help='Number of tasks to run (default: all)')
    parser.add_argument('--retries', type=int, default=2, help='Max retries per task')
    parser.add_argument('--output', help='Output file for results (JSON)')
    
    args = parser.parse_args()
    
    use_real = args.real
    if not use_real and not args.mock:
        use_real = False  # Default to mock
    
    if use_real:
        # Check for API keys - accept any valid provider key
        provider_keys = [
            'GROQ_KEY', 'GEMINI_KEY', 'OPENAI_KEY', 'ANTHROPIC_KEY', 
            'DEEPSEEK_KEY', 'OPENROUTER_KEY', 'CEREBRAS_KEY', 
            'NVIDIA_NIM_KEY', 'NVIDIA_NIM_API_KEY'
        ]
        has_valid_key = any(
            os.environ.get(key) and os.environ.get(key) != f'your_{key.lower()}'
            for key in provider_keys
        )
        if not has_valid_key:
            print("ERROR: No real API keys configured in .env")
            print("Set GROQ_KEY, NVIDIA_NIM_KEY, GEMINI_KEY, OPENAI_KEY, or other provider keys in .env to run with --real")
            print("Falling back to mock mode...")
            use_real = False
    
    runner = StressTestRunner(use_real_llm=use_real)
    
    tasks = STRESS_TASKS
    if args.tasks:
        tasks = tasks[:args.tasks]
    
    suite = runner.run_suite(tasks, max_retries=args.retries)
    
    # Print summary
    summary = suite.summary()
    print(f"\n{'#'*60}")
    print(f"# STRESS TEST SUMMARY")
    print(f"{'#'*60}")
    print(f"Total Tests: {summary['total']}")
    print(f"Passed: {summary['passed']}")
    print(f"Failed: {summary['failed']}")
    print(f"Success Rate: {summary['success_rate']:.1f}%")
    print(f"Avg Attempts: {summary['avg_attempts']:.1f}")
    print(f"Avg Steps: {summary['avg_steps']:.1f}")
    print(f"Avg Duration: {summary['avg_duration']:.1f}s")
    print(f"Total Duration: {summary['total_duration']:.1f}s")
    
    # Detailed results
    print(f"\n{'='*60}")
    print("DETAILED RESULTS")
    print(f"{'='*60}")
    for r in suite.results:
        status = "PASS" if r.success else "FAIL"
        print(f"  [{status}] {r.task_name}")
        print(f"      Attempts: {r.attempts} | Steps: {r.total_steps} | Quality: {r.quality_score} | Time: {r.duration_seconds:.1f}s")
        if r.error:
            print(f"      Error: {r.error[:100]}")
    
    # Save results if output specified
    if args.output:
        output_data = {
            "timestamp": datetime.now().isoformat(),
            "mode": "real" if use_real else "mock",
            "summary": summary,
            "results": [
                {
                    "task_name": r.task_name,
                    "goal": r.goal,
                    "success": r.success,
                    "attempts": r.attempts,
                    "total_steps": r.total_steps,
                    "tools_used": r.tools_used,
                    "duration_seconds": r.duration_seconds,
                    "quality_score": r.quality_score,
                    "error": r.error,
                    "traceback": r.traceback_str,
                }
                for r in suite.results
            ]
        }
        with open(args.output, 'w') as f:
            json.dump(output_data, f, indent=2)
        print(f"\nResults saved to {args.output}")
    
    # Exit with appropriate code
    sys.exit(0 if summary['failed'] == 0 else 1)


if __name__ == "__main__":
    main()