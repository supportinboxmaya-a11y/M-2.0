"""Tests for LLM Router"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from llm.router import LLMRouter

def test_router_available_providers():
    router = LLMRouter()
    providers = router.available_providers()
    assert isinstance(providers, list)
    print(f"PASS test_router_available_providers: {providers}")

def test_router_stats():
    router = LLMRouter()
    stats = router.get_stats()
    assert "total_requests" in stats
    assert "available_providers" in stats
    print("PASS test_router_stats")

def test_router_no_provider():
    router = LLMRouter()
    if not router.available_providers():
        print("SKIP test_router_chat: No providers available")
        return
    print("PASS test_router_no_provider")

if __name__ == "__main__":
    test_router_available_providers()
    test_router_stats()
    test_router_no_provider()
    print("\nAll router tests passed!")
