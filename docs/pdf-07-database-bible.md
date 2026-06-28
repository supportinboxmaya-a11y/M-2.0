# PDF 07 - Database Bible

## 1. Database Stack
- Primary: SQLite (local) / PostgreSQL (production)
- Cache: Redis / Cloudflare KV
- Vector: ChromaDB
- Cloud: Cloudflare D1

## 2. Core Tables

### tasks
- id TEXT PRIMARY KEY
- goal TEXT NOT NULL
- status TEXT (pending/running/done/failed)
- result TEXT
- error TEXT
- steps JSON
- created_at DATETIME
- completed_at DATETIME
- cost_usd REAL
- tokens_used INTEGER
- provider_used TEXT

### memories
- id TEXT PRIMARY KEY
- content TEXT NOT NULL
- type TEXT (short_term/long_term/episodic/semantic/vector/general/chat)
- metadata JSON
- created_at DATETIME

### episodes
- id TEXT PRIMARY KEY
- goal TEXT
- steps JSON
- result TEXT
- success BOOLEAN
- created_at DATETIME

### experiences
- id TEXT PRIMARY KEY
- task TEXT
- lesson TEXT
- pattern TEXT
- future_tip TEXT
- success BOOLEAN
- created_at DATETIME

## 3. Indexing
- tasks: status, created_at
- memories: type, created_at
- episodes: success, created_at
- experiences: success

## 4. Vector DB Schema
- Collection: maya_memories
- Embedding: text-embedding-ada-002
- Metadata: type, timestamp, task_id
