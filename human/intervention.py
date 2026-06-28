class InterventionHandler:
    def __init__(self):
        self.intervention_mode = False

    def enable(self):
        self.intervention_mode = True

    def disable(self):
        self.intervention_mode = False

    def check_interrupt(self) -> bool:
        if self.intervention_mode:
            response = input("\n🛑 Continue? (y/n): ").strip().lower()
            return response != "y"
        return False

    def pause_and_prompt(self, message: str) -> str:
        print(f"\n⏸️  {message}")
        return input("   Your input: ").strip()
