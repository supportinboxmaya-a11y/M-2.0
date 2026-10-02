# LLM Provider Configuration Report

## Configured Providers

| Provider | Label | Configured | Enabled | Active | Env Key | Priority (Default) |
|----------|-------|------------|---------|--------|---------|-------------------|
| **Groq** | Groq | ❌ No | ✅ Yes | ❌ No | `GROQ_KEY` / `GROQ_API_KEY` | 1 (Highest) |
| **Cerebras** | Cerebras | ❌ No | ✅ Yes | ❌ No | `CEREBRAS_KEY` / `CEREBRAS_API_KEY` | 2 |
| **OpenRouter** | OpenRouter | ❌ No | ✅ Yes | ❌ No | `OPENROUTER_KEY` / `OPENROUTER_API_KEY` | 3 |
| **Gemini** | Google Gemini | ❌ No | ✅ Yes | ❌ No | `GEMINI_KEY` / `GEMINI_API_KEY` | 4 |
| **DeepSeek** | DeepSeek | ❌ No | ✅ Yes | ❌ No | `DEEPSEEK_KEY` | 5 |
| **NVIDIA NIM** | NVIDIA NIM | ❌ No | ✅ Yes | ❌ No | `NVIDIA_NIM_KEY` / `NVIDIA_NIM_API_KEY` | 8 |
| **OpenAI** | OpenAI | ❌ No | ✅ Yes | ❌ No | `OPENAI_KEY` / `OPENAI_API_KEY` | 9 |
| **Anthropic (Claude)** | Anthropic | ❌ No | ✅ Yes | ❌ No | `ANTHROPIC_KEY` / `ANTHROPIC_API_KEY` | 9 |
| **OmniRoute** | OmniRoute | ❌ No | ✅ Yes | ❌ No | `OMNIROUTE_API_KEY` | - |
| **DeepSeek** | DeepSeek | ❌ No | ✅ Yes | ❌ No | `DEEPSEEK_KEY` | - |
| **Cerebras** | Cerebras | ❌ No | ✅ Yes | ❌ No | `CEREBRAS_KEY` / `CEREBRAS_API_KEY` | - |
| **OpenRouter** | OpenRouter | ❌ No | ✅ Yes | ❌ No | `OPENROUTER_KEY` / `OPENROUTER_API_KEY` | - |
| **OmniRoute** | OmniRoute | ❌ No | ✅ Yes | ❌ No | `OMNIROUTE_API_KEY` | - |
| **Local LLM** | Local LLM | ✅ Yes | ✅ Yes | ✅ **Yes** | (no key needed) | 5 (fallback) |
| **Local LLM (Fast)** | Local LLM (Fast) | ✅ Yes | ✅ Yes | ❌ No | (no key needed) | - |

### Additional Provider Slots (Not yet loaded):
- **NVIDIA NIM** - requires `NVIDIA_NIM_KEY` / `NVIDIA_NIM_API_KEY`
- **OpenAI** - requires `OPENAI_KEY` / `OPENAI_API_KEY`
- **Anthropic (Claude)** - requires `ANTHROPIC_KEY` / `ANTHROPIC_API_KEY`

---

## Active/Default Provider

**Current Active: `local` (Local LLM)**
- This is the **only active provider** currently available
- No API key required - runs locally
- Used as fallback when no other providers are configured
- Limited capabilities compared to cloud providers

---

## Missing API Keys (Required in `.env`)

The following API keys need to be added to `.env` for their respective providers to become active:

| Provider | Env Variables (both formats work) | Status |
|----------|-----------------------------------|--------|
| **Groq** | `GROQ_KEY` or `GROQ_API_KEY` | ❌ MISSING |
| **Cerebras** | `CEREBRAS_KEY` or `CEREBRAS_API_KEY` | ❌ MISSING |
| **OpenRouter** | `OPENROUTER_KEY` or `OPENROUTER_API_KEY` | ❌ MISSING |
| **Google Gemini** | `GEMINI_KEY` or `GEMINI_API_KEY` | ❌ MISSING |
| **DeepSeek** | `DEEPSEEK_KEY` | ❌ MISSING |
| **NVIDIA NIM** | `NVIDIA_NIM_KEY` or `NVIDIA_NIM_API_KEY` | ❌ MISSING |
| **OpenAI** | `OPENAI_KEY` or `OPENAI_API_KEY` | ❌ MISSING |
| **Anthropic (Claude)** | `ANTHROPIC_KEY` or `ANTHROPIC_API_KEY` | ❌ MISSING |
| **OpenRouter** | `OPENROUTER_KEY` or `OPENROUTER_API_KEY` | ❌ MISSING |
| **Cerebras** | `CEREBRAS_KEY` or `CEREBRAS_API_KEY` | ❌ MISSING |
| **OmniRoute** | `OMNIROUTE_API_KEY` | ❌ MISSING |

**Note**: Each provider accepts both `_KEY` and `_API_KEY` suffixes (e.g., `GROQ_KEY` and `GROQ_API_KEY` both work).

---

## Fallback/Routing Logic

### Default Priority Order (hardcoded in router.py)
```python
DEFAULT_PRIORITY = [
    "groq",           # 1 - Fast, free tier
    "cerebras",       # 2 - Fast inference
    "openrouter",     # 3 - Access to many models via OpenRouter
    "gemini",         # 4 - Google's models
    "deepseek",       # 5 - DeepSeek models
    "local",          # 6 - Local fallback
    "local_fast",     # 7 - Fast local
    "nvidia_nim",     # 8 - NVIDIA NIM
    "openai",         # 9 - OpenAI
    "claude",         # 10 - Anthropic
]
```

### Task-Type Specific Routing
```python
preferences = {
    "planning":       ["groq", "cerebras", "openrouter", "gemini", "local_fast", "local"],
    "reasoning":      ["groq", "cerebras", "openrouter", "gemini", "local", "local_fast"],
    "tool_use":       ["groq", "cerebras", "local", "local_fast"],
    "coding":         ["groq", "cerebras", "openrouter", "local"],
    "fast":           ["groq", "cerebras", "local_fast"],
    "analysis":       ["groq", "cerebras", "local", "local_fast"],
    "creative":       ["groq", "cerebras", "local", "local_fast"],
    "general":        ["groq", "cerebras", "openrouter", "gemini", "local", "local_fast", "nvidia_nim"],
}
```

### Fallback Mechanism
1. **Primary Selection**: Best provider for task type (from preferences above)
2. **Fallback Chain**: If primary fails, tries next in `DEFAULT_PRIORITY` that is healthy
3. **Health Checks**: 
   - Provider is "healthy" if: enabled + configured + available + error_count < 5
   - Auto-recovery after `LLM_PROVIDER_COOLDOWN` (default 120s) from last error
   - Error threshold: 5 consecutive failures = disabled until cooldown expires
4. **Hard Approval Gates**: High-risk actions (deploy, publish, spend money) require explicit human approval regardless of provider health

---

## Usage Tracking Status

### Current State
- **Total Requests**: 0
- **Successful Requests**: 0
- **Success Rate**: 0%
- **Request Log**: Limited to last 100 entries (stored in memory)

### Cost Tracking
- **Budget Tracking**: Enabled via `CostTracker` class
- **Budget Limit**: Configurable via `MAYA_DAILY_BUDGET_USD` (default: no limit)
- **Cost Recording**: Each provider reports token usage → recorded in `CostTracker`
- **Current Usage**: No usage recorded (no API keys configured)

### Tracking Infrastructure
- `CostTracker` class: Tracks spending per provider
- Budget enforcement: Returns error if budget exceeded
- Per-request cost logging available
- No persistent storage of usage data (in-memory only, resets on restart)

---

## Current `.env` Status

**No `.env` file exists** - only `.env.example` is present.

### Required Action
Create `.env` file from `.env.example` and add at least one API key:

```bash
cp .env.example .env
# Then edit .env to add at least one key:
# GROQ_KEY=your_groq_key_here
# or
# OPENROUTER_KEY=your_openrouter_key_here
# etc.
```

---

## Summary & Recommendations

### Immediate Actions
1. **Create `.env` file**: `cp .env.example .env`
2. **Add at least one API key** - Recommended order:
   - **Groq** (fast, generous free tier) - `GROQ_KEY`
   - **OpenRouter** (access to many models) - `OPENROUTER_KEY`
   - **NVIDIA NIM** (fast inference) - `NVIDIA_NIM_KEY`

### Priority for Production
| Priority | Provider | Reason |
|----------|----------|--------|
| 1 | Groq | Fast, free tier, reliable |
| 2 | OpenRouter | Access to many models, free tier |
| 3 | NVIDIA NIM | Fast inference, free tier |
| 4 | Cerebras | Ultra-fast inference |
| 5 | Google Gemini | Good quality, free tier |
| 6 | Anthropic Claude | High quality, paid |
| 7 | OpenAI | High quality, paid |

### Monitoring Needed
- No persistent usage tracking (in-memory only)
- No rate limit monitoring dashboard
- No cost alerts configured
- Consider adding persistent storage for usage analytics

---

## Architecture Notes

### Provider Health Management
- **Health Check**: Runs on startup and periodically
- **Cooldown Recovery**: 120s (configurable via `LLM_PROVIDER_COOLDOWN`)
- **Error Threshold**: 5 consecutive failures = disabled
- **Auto-Recovery**: After cooldown, re-probes provider

### Provider State Persistence
- Enabled/disabled state saved to `STORAGE_DIR/provider_state.json`
- Survives restarts
- `router.set_enabled(provider, bool)` for runtime control

### Error Diagnostics
- Automatic error categorization (auth, rate-limit, network, context-length, model-not-found)
- Human-readable diagnostics logged on failure
- Auto-fallback to next healthy provider