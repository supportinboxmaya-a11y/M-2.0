# Installation Manual

## Requirements
- Python 3.10+
- Node.js 18+
- Groq or Gemini API key (free)

## Backend
1. git clone https://github.com/supportinboxmaya-a11y/M-2.0.git
2. cd M-2.0
3. pip install -r requirements.txt
4. cp .env.example .env
5. Add API keys to .env
6. python main.py

## Frontend
1. git clone https://github.com/supportinboxmaya-a11y/Maya_frontend.git
2. cd Maya_frontend
3. npm install
4. npm run dev
5. Open http://localhost:3000

## API Keys
- Groq (Free): console.groq.com
- Gemini (Free): aistudio.google.com
- OpenAI: platform.openai.com
- Anthropic: console.anthropic.com

## Troubleshoot
- No provider: Add API key in Settings
- Tool not found: pip install -r requirements.txt
- Memory error: Delete storage/ and restart
