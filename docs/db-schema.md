# Database Schema

## tasks
- id TEXT PRIMARY KEY
- goal TEXT NOT NULL
- status TEXT
- result TEXT
- error TEXT
- steps JSON
- created_at DATETIME
- cost_usd REAL
- tokens_used INTEGER
- provider_used TEXT

## memories
- id TEXT PRIMARY KEY
- content TEXT NOT NULL
- type TEXT
- metadata JSON
- created_at DATETIME

## episodes
- id TEXT PRIMARY KEY
- goal TEXT
- steps JSON
- result TEXT
- success BOOLEAN
- created_at DATETIME

## experiences
- id TEXT PRIMARY KEY
- task TEXT
- lesson TEXT
- pattern TEXT
- future_tip TEXT
- success BOOLEAN
- created_at DATETIME
