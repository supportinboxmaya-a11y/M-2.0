import os
import sys
from dotenv import load_dotenv
load_dotenv()

from core.maya import Maya

def main():
    maya = Maya()
    print("\n" + "="*50)
    print("  Maya 2.0 ULTRA - Autonomous AI Agent")
    print("="*50)
    print("Commands: 'run <goal>' | 'chat <msg>' | 'quit'")
    print("="*50 + "\n")

    while True:
        try:
            user_input = input("You: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ["quit", "exit", "q"]:
                print("👋 Maya shutting down...")
                break
            elif user_input.lower().startswith("run "):
                goal = user_input[4:].strip()
                result = maya.run(goal)
                print(f"\nMaya: {'✅ ' + result['result'] if result['success'] else '❌ Failed'}\n")
            elif user_input.lower().startswith("chat "):
                msg = user_input[5:].strip()
                response = maya.chat(msg)
                print(f"\nMaya: {response}\n")
            else:
                response = maya.chat(user_input)
                print(f"\nMaya: {response}\n")
        except KeyboardInterrupt:
            print("\n👋 Interrupted. Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
