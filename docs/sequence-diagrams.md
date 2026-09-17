# Sequence Diagrams

## Task Execution
User -> Frontend: Enter goal
Frontend -> API: POST /agent/run
API -> WorkflowEngine: run(goal)
WorkflowEngine -> Planner: plan(goal)
Planner -> LLMRouter: chat(prompt)
LLMRouter -> Provider: API call
Provider -> LLMRouter: response
Planner -> WorkflowEngine: steps
WorkflowEngine -> Executor: execute_step
Executor -> Tool: run(input)
Tool -> Executor: result
Executor -> Verifier: verify
Verifier -> WorkflowEngine: success
WorkflowEngine -> API: done
API -> Frontend: WebSocket task:done
Frontend -> User: Show result

## Memory Retrieval
Agent -> MemoryManager: get_relevant(goal)
MemoryManager -> ShortTerm: get_all()
MemoryManager -> LongTerm: search(goal)
MemoryManager -> VectorDB: similarity_search(goal)
MemoryManager -> Agent: merged memories
