# Maya 2.0 ULTRA - Autonomous AI Agent

Maya is an autonomous, modular AI agent that understands goals, plans tasks, executes them using tools, verifies results, recovers from failures, and continuously improves over time.

---

## Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/supportinboxmaya-a11y/M-2.0.git
cd M-2.0
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Set up API keys
Edit the `.env` file and add your keys.

### 4. Run Maya
```bash
python main.py
```

---

## API Keys Setup

Edit `.env` file:

```env
# Required (at least one)
GROQ_KEY=your_groq_key          # Free at console.groq.com
GEMINI_KEY=your_gemini_key      # Free at aistudio.google.com

# Optional
OPENAI_KEY=your_openai_key
ANTHROPIC_KEY=your_anthropic_key
DEEPSEEK_KEY=your_deepseek_key

# For web search
GOOGLE_API_KEY=your_google_key
GOOGLE_CSE_ID=your_cse_id
```

Minimum requirement: At least one of `GROQ_KEY` or `GEMINI_KEY`

---

## Usage

```
You: run Search the web for latest AI news and summarize
You: run Write a Python script to sort a list and save it to file
You: run Find top 5 Python libraries for data science
You: chat What can you do?
You: quit
```

---

## How Maya Works

```
User Goal
    |
Planner  --> Creates step-by-step plan
    |
Executor --> Runs each step (tools or LLM)
    |
Verifier --> Checks if goal is achieved
    |
Learner  --> Extracts lessons for next time
    |
If failed --> Fallback Manager --> Replan & Retry
```

---

## Folder Structure

```
M-2.0/
|-- main.py                  # Entry point
|-- .env                     # API keys (never commit!)
|-- requirements.txt         # Dependencies
|-- backup_restore.py        # Backup system
|
|-- core/
|   |-- maya.py              # Main agent brain
|   |-- planner.py           # Goal to step-by-step plan
|   |-- reasoner.py          # Deep thinking and decisions
|   |-- executor.py          # Execute steps with tools
|   |-- verifier.py          # Check if goal is achieved
|   |-- workflow_engine.py   # Plan-Execute-Verify-Learn loop
|   |-- fallback_manager.py  # Failure recovery
|   `-- task_manager.py      # Task lifecycle
|
|-- llm/
|   |-- router.py            # Smart LLM routing
|   |-- prompt_builder.py    # Prompt templates
|   `-- providers/           # Groq, Gemini, OpenAI, Claude, DeepSeek
|
|-- memory/
|   |-- memory_manager.py    # Unified memory interface
|   |-- short_term.py        # Current session memory
|   |-- long_term.py         # SQLite persistent memory
|   |-- episodic_memory.py   # Past task episodes
|   |-- semantic_memory.py   # Facts and knowledge
|   |-- vector_memory.py     # Semantic search (ChromaDB)
|   `-- context_manager.py   # Context tracking
|
|-- tools/
|   |-- registry.py          # Tool management
|   |-- web/                 # Web search and scraping
|   |-- files/               # File read/write
|   |-- code/                # Python code execution
|   `-- system/              # Shell and terminal
|
|-- learning/
|   |-- improvement_engine.py  # Learn from every task
|   `-- experience_store.py    # Store lessons
|
|-- security/
|   |-- risk_checker.py      # Risk assessment
|   |-- permissions.py       # Tool permissions
|   `-- sandbox.py           # File system sandbox
|
|-- human/
|   |-- approval.py          # Human approval for risky actions
|   |-- feedback.py          # Collect user feedback
|   `-- intervention.py      # Manual intervention
|
`-- storage/                 # Auto-created at runtime
    |-- memory/              # Database files
    |-- logs/                # Log files
    `-- backups/             # Code backups
```

---

## Available Tools

| Tool | Description |
|------|-------------|
| web_search | Search the internet |
| web_scrape | Read any webpage |
| read_file | Read files from disk |
| write_file | Write files to disk |
| list_files | List directory contents |
| run_code | Execute Python code |
| run_shell | Run shell commands |
| run_terminal | Execute terminal commands |
| list_processes | List running processes |

---

## Supported LLM Providers

| Provider | Models | Speed | Best For |
|----------|--------|-------|----------|
| Groq | LLaMA 3, Mixtral | Fastest | General tasks |
| Gemini | 1.5 Flash, Pro | Fast | Research, long context |
| OpenAI | GPT-4o, GPT-4 | Smart | Complex reasoning |
| Claude | Haiku, Sonnet | Best | Writing, analysis |
| DeepSeek | Chat, Coder | Best | Coding, math |
| Local | Ollama | Private | Offline use |

---

## Backup and Restore

```bash
# Backup before any update
python backup_restore.py backup

# List all backups
python backup_restore.py list

# Restore last backup
python backup_restore.py restore

# Restore specific backup
python backup_restore.py restore 2
```

---

## Adding New Tools

```python
# In tools/tool_manager.py
from tools.my_tool import MyTool

my_tool = MyTool()
self.registry.register(
    name="my_tool",
    func=my_tool.run,
    description="What this tool does",
    category="custom"
)
```

---

## Safety Features

- Risk Checker: Blocks dangerous commands automatically
- Sandbox: File operations limited to workspace/
- Human Approval: Asks before high-risk actions
- Intervention: User can pause/stop at any time

---

## Troubleshooting

**No provider available error:**
- Make sure at least one API key is set in `.env`
- Get a free Groq key at console.groq.com

**Tool not found error:**
- Check tools/tool_manager.py to see registered tools
- Make sure required packages are installed

**Memory/DB error:**
- Delete the storage/ folder and restart
- Maya will recreate it automatically

**Import error:**
- Run `pip install -r requirements.txt` again
- Make sure you are in the M-2.0/ directory

---

## License

MIT License - Free to use, modify, and distribute.

---

Built with love - Maya 2.0 ULTRA
