from infrastructure.cognitive_kernel import CognitiveKernel
kernel = CognitiveKernel()
print("Kernel initialized")

from llm.router import LLMRouter
router = LLMRouter()
print("Active providers:", router.available_providers())
print("Best for reasoning:", router.best_provider("reasoning"))

result = kernel.process_goal("Test local brain integration", execute=False)
print("Goal proposed:", result.get("proposed", True))
print("Status:", result.get("status"))
