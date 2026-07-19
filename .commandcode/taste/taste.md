# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# python
- Use optional imports with fallback for any heavy native dependencies. Confidence: 0.85
- Run 'python -m py_compile <file>' after each edit and fix errors before finishing. Confidence: 0.85

# architecture
- Never break server boot - wrap new features in try/except soft-fail blocks that print a WARNING. Confidence: 0.85
- Design all features for HTTP API usage from mobile phone; include phone notifications where relevant. Confidence: 0.85
- Commit one task at a time via git before moving to the next. Confidence: 0.85

# fastapi
- Reuse config.settings paths, module singletons, Depends(get_current_user), enterprise/rbac, workspace + scoped_memory patterns. Confidence: 0.70

