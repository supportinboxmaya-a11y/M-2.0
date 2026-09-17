# PDF 05 - Backend Bible Part 1

## 1. Architecture Overview
- Language: Python 3.10+
- Framework: FastAPI
- Pattern: Modular monolith
- Deployment: Docker + Cloudflare Workers

## 2. API Gateway
- Route: /api/v1/*
- Auth middleware
- Rate limiting
- Request validation
- Response formatting
- Error handling

## 3. Authentication
- JWT tokens
- OAuth2 (Google, GitHub)
- Session management
- Token refresh
- Role-based access

## 4. Model Router
- Provider priority per task type
- Automatic fallback
- Health check per provider
- Cost tracking per call
- Token counting

### Provider Priority
- coding: DeepSeek → Groq → OpenAI
- research: Gemini → Claude → OpenAI
- fast: Groq → Gemini → DeepSeek
- general: Groq → Gemini → DeepSeek → OpenAI → Claude

## 5. Agent Engine
- Goal parsing
- Plan generation
- Step execution
- Result verification
- Failure recovery
- Learning extraction

## 6. Workflow Engine
- Plan → Execute → Verify → Learn loop
- Max 3 retries on failure
- Step-by-step logging
- Context management
- Memory integration
