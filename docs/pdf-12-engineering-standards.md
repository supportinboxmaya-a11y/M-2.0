# PDF 12 - Engineering Standards

## 1. Folder Structure
maya/
  core/          # Agent brain
  llm/           # LLM routing
  memory/        # Memory system
  tools/         # All tools
  learning/      # Self-improvement
  security/      # Risk & permissions
  utils/         # Helpers
  config/        # Settings

## 2. Coding Standards
- Python: PEP 8, type hints required
- TypeScript: strict mode, no any
- Functions: max 50 lines
- Files: max 300 lines
- Comments: English only
- Naming: snake_case (Python), camelCase (TS)

## 3. Git Workflow
- main: production only
- develop: integration branch
- feature/name: new features
- fix/name: bug fixes
- docs/name: documentation

### Commit Messages
feat: new feature
fix: bug fix
docs: documentation
refactor: code refactor
test: add tests
chore: maintenance

## 4. Testing Standards
- Unit tests: pytest (Python), vitest (TS)
- Coverage: minimum 80%
- E2E tests: Playwright
- Test naming: test_[function]_[scenario]

## 5. QA Process
1. Developer self-review
2. Automated tests pass
3. Code review (1 approval)
4. Staging deployment
5. Manual QA
6. Production deployment

## 6. Documentation Standards
- Every function: docstring
- Every API endpoint: OpenAPI spec
- Every component: JSDoc
- README: updated per release

## 7. Claude Instructions
When implementing Maya:
- Read all documentation before coding
- Follow documentation exactly
- No simplification of features
- Maintain modular architecture
- Production-quality code only
- Treat docs as source of truth

## 8. Roadmap
Q1 2025: Foundation (Chat, Memory, Auth)
Q2 2025: Power Features (Workflow, Plugins)
Q3 2025: Enterprise (RBAC, SSO, Security)
Q4 2025: Marketplace & Mobile App
