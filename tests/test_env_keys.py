"""Tests for env_first (Phase 0)"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.settings import env_first

def test_primary():
    os.environ["T_KEY"]="a"; os.environ["T_API_KEY"]="b"
    assert env_first("T_KEY","T_API_KEY")=="a"; print("PASS primary")

def test_fallback():
    os.environ.pop("T_KEY",None); os.environ["T_API_KEY"]="b"
    assert env_first("T_KEY","T_API_KEY")=="b"; print("PASS fallback")

def test_default():
    os.environ.pop("T_KEY",None); os.environ.pop("T_API_KEY",None)
    assert env_first("T_KEY", default="x")=="x"; print("PASS default")

if __name__=="__main__":
    test_primary(); test_fallback(); test_default(); print("All env tests passed")
