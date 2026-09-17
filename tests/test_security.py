"""Tests for Security System"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from security.risk_checker import RiskChecker
from security.permissions import PermissionManager

def test_risk_checker_safe():
    checker = RiskChecker()
    result = checker.check("search for AI news")
    assert result["allow"] == True
    print("PASS test_risk_checker_safe")

def test_risk_checker_dangerous():
    checker = RiskChecker()
    result = checker.check("rm -rf /")
    assert result["allow"] == False
    print("PASS test_risk_checker_dangerous")

def test_permissions():
    pm = PermissionManager()
    assert pm.is_allowed("web_search") == True
    pm.block_tool("web_search")
    assert pm.is_allowed("web_search") == False
    pm.allow_tool("web_search")
    assert pm.is_allowed("web_search") == True
    print("PASS test_permissions")

if __name__ == "__main__":
    test_risk_checker_safe()
    test_risk_checker_dangerous()
    test_permissions()
    print("\nAll security tests passed!")
