# PDF 06 - Backend Bible Part 2

## 1. Memory Engine
- Short-term: in-memory, 50 items, session only
- Long-term: SQLite persistent
- Episodic: full task run records
- Semantic: facts & knowledge base
- Vector: ChromaDB semantic search

## 2. Tool Engine
- Tool registry
- Permission checker
- Sandbox execution
- Input/Output logging
- Error handling
- Custom tool loader

## 3. Plugin Engine
- Plugin manifest validation
- Sandboxed execution
- Tool registration
- Marketplace integration
- Enable/Disable runtime

## 4. Queue System
- Task queue (FIFO)
- Priority queue
- Retry queue
- Dead letter queue
- Status tracking

## 5. Event Bus
- Task events
- Memory events
- Tool events
- Provider events
- WebSocket broadcast

## 6. Storage
- Local: workspace/ directory
- Cloud: Cloudflare R2
- DB: SQLite (local) / D1 (cloud)
- Cache: Redis / KV Store

## 7. Security
- Risk level checker (low/medium/high/critical)
- Dangerous keyword detection
- File sandbox (workspace/ only)
- Approval modes: auto/human/skip
- Audit logging

## 8. Scaling
- Horizontal scaling via Docker
- Cloudflare Workers for edge
- Stateless API design
- Cache-first architecture
