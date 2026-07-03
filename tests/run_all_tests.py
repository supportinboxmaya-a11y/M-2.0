"""Run all Maya tests"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def run_test_file(filename):
    print(f"\n{'='*40}")
    print(f"Running {filename}...")
    print('='*40)
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("test", filename)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False

if __name__ == "__main__":
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    test_files = [
        "test_memory.py",
        "test_tools.py",
        "test_security.py",
        "test_planner.py",
        "test_router.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
        "test_env_keys.py",
        "test_infrastructure.py",
        "test_memory_phase2.py",
        "test_brain_phase3.py",
        "test_agents_phase4.py",
        "test_tools_phase5.py",
        "test_workflows_phase6.py",
        "test_autonomous_phase7.py",
        "test_router_phase8.py",
        "test_enterprise_phase9.py",
        "test_learning_phase10.py",
    ]

    passed = 0
    failed = 0

    for test_file in test_files:
        path = os.path.join(tests_dir, test_file)
        if run_test_file(path):
            passed += 1
        else:
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed")
    print('='*40)
