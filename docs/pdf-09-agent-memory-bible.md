# PDF 09 - Agent & Memory Bible

## 1. Agent Protocol
- Goal → Plan → Execute → Verify → Learn
- Max steps: 25
- Max retries: 3
- Timeout: 60 seconds per step

## 2. Planning Algorithm
1. Analyze goal complexity
2. Break into executable steps
3. Assign tools per step
4. Estimate resource needs
5. Return JSON plan

## 3. Agent Communication
- Single agent: direct execution
- Multi-agent: coordinator + workers
- Message passing via event bus
- Shared memory access

## 4. Memory Retrieval Algorithm
1. Check short-term (current session)
2. Search long-term (SQLite FTS)
3. Vector similarity search (ChromaDB)
4. Merge & rank results
5. Return top N memories

## 5. RAG Implementation
- Chunk documents into 512 token blocks
- Embed with text-embedding model
- Store in ChromaDB
- Retrieve top 5 similar chunks
- Inject into prompt context

## 6. Knowledge Graph
- Entity extraction from conversations
- Relationship mapping
- Graph traversal for context
- Auto-update from task results

## 7. Learning System
- Extract lesson from each task
- Identify patterns
- Generate future tips
- Store in experiences table
- Apply on similar future tasks
