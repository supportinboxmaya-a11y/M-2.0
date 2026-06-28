from typing import Optional

class FeedbackCollector:
    def __init__(self):
        self.feedback_log = []

    def collect(self, task: str, result: str) -> Optional[str]:
        print(f"\n📝 Task: {task}")
        print(f"   Result: {result[:200]}...")
        feedback = input("   Feedback (or Enter to skip): ").strip()
        if feedback:
            self.feedback_log.append({"task": task, "feedback": feedback})
        return feedback or None

    def get_all(self):
        return self.feedback_log
