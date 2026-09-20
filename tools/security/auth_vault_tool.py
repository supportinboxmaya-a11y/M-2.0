"""
Maya 2.0 - Auth & Vault Tools
Provides JWT generation/verification, password hashing, API key management, rate limiting.
"""

import os
import jwt
import hashlib
import secrets
import time
from datetime import datetime, timedelta
from typing import Dict, Optional
from pathlib import Path
from config.settings import WORKSPACE_DIR, SECRET_KEY, JWT_ALGORITHM, JWT_EXPIRATION_DAYS


class AuthVaultTool:
    """Authentication and secrets management."""
    
    def __init__(self):
        self.vault_path = Path(WORKSPACE_DIR) / "vault"
        self.vault_path.mkdir(exist_ok=True)
        self.rate_limits = {}
        
    def generate_jwt(self, payload: dict, expires_days: int = None) -> dict:
        """Generate a JWT token."""
        try:
            exp_days = expires_days or JWT_EXPIRATION_DAYS
            exp = datetime.utcnow() + timedelta(days=exp_days)
            payload = {**payload, "exp": exp, "iat": datetime.utcnow()}
            token = jwt.encode(payload, SECRET_KEY, algorithm=JWT_ALGORITHM)
            return {"success": True, "token": token, "expires_at": exp.isoformat()}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def verify_jwt(self, token: str) -> dict:
        """Verify a JWT token."""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[JWT_ALGORITHM])
            return {"success": True, "payload": payload, "valid": True}
        except jwt.ExpiredSignatureError:
            return {"success": False, "error": "Token expired", "valid": False}
        except jwt.InvalidTokenError as e:
            return {"success": False, "error": f"Invalid token: {e}", "valid": False}
        except Exception as e:
            return {"success": False, "error": str(e), "valid": False}

    def hash_password(self, password: str) -> dict:
        """Hash a password using PBKDF2."""
        try:
            salt = secrets.token_bytes(16)
            hash_bytes = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
            return {
                "success": True,
                "hash": hash_bytes.hex(),
                "salt": salt.hex(),
                "algorithm": "pbkdf2_sha256",
                "iterations": 100000
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    def verify_password(self, password: str, hash_hex: str, salt_hex: str) -> dict:
        """Verify a password against hash."""
        try:
            salt = bytes.fromhex(salt_hex)
            hash_bytes = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
            valid = secrets.compare_digest(hash_bytes.hex(), hash_hex)
            return {"success": True, "valid": valid}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def role_based_access(self, user_role: str, required_role: str) -> dict:
        """Check if user role has required access."""
        role_hierarchy = {
            "SUPER_ADMIN": 5,
            "ADMIN": 4,
            "OPERATOR": 3,
            "DEVELOPER": 2,
            "VIEWER": 1,
            "GUEST": 0
        }
        user_level = role_hierarchy.get(user_role.upper(), 0)
        required_level = role_hierarchy.get(required_role.upper(), 0)
        return {
            "success": True,
            "allowed": user_level >= required_level,
            "user_role": user_role,
            "required_role": required_role,
            "user_level": user_level,
            "required_level": required_level
        }

    def api_key_vault(self, action: str = "get", key_name: str = "", key_value: str = "") -> dict:
        """Manage API keys in local vault."""
        key_file = self.vault_path / f"{key_name}.key"
        
        if action == "get":
            if key_file.exists():
                return {"success": True, "key_name": key_name, "value": key_file.read_text().strip()}
            return {"success": False, "error": f"Key {key_name} not found"}
        
        elif action == "set":
            if not key_name:
                return {"success": False, "error": "key_name required"}
            key_file.write_text(key_value)
            os.chmod(key_file, 0o600)
            return {"success": True, "message": f"Key {key_name} stored"}
        
        elif action == "delete":
            if key_file.exists():
                key_file.unlink()
                return {"success": True, "message": f"Key {key_name} deleted"}
            return {"success": False, "error": f"Key {key_name} not found"}
        
        elif action == "list":
            keys = [f.stem for f in self.vault_path.glob("*.key")]
            return {"success": True, "keys": keys}
        
        return {"success": False, "error": f"Invalid action: {action}"}

    def rate_limit_check(self, identifier: str, max_requests: int = 100, window_seconds: int = 60) -> dict:
        """Check rate limit for an identifier."""
        now = time.time()
        if identifier not in self.rate_limits:
            self.rate_limits[identifier] = []
        
        # Clean old entries
        self.rate_limits[identifier] = [
            t for t in self.rate_limits[identifier] if now - t < window_seconds
        ]
        
        current = len(self.rate_limits[identifier])
        allowed = current < max_requests
        
        if allowed:
            self.rate_limits[identifier].append(now)
        
        return {
            "success": True,
            "allowed": allowed,
            "current": current + (1 if allowed else 0),
            "limit": max_requests,
            "window_seconds": window_seconds,
            "reset_at": now + window_seconds
        }

    def session_revoke(self, session_id: str) -> dict:
        """Revoke a session (placeholder - would integrate with session store)."""
        # This would typically remove from a session store
        # For now, just return success as a stub
        return {"success": True, "message": f"Session {session_id} revoked (stub)"}

    # Tool registry entry points
    def generate_jwt(self, payload: dict, expires_days: int = None, **kwargs) -> str:
        result = self.generate_jwt(payload, expires_days)
        if result.get("success"):
            return f"Token: {result['token']}"
        return f"Error: {result.get('error')}"

    def verify_jwt(self, token: str, **kwargs) -> str:
        result = self.verify_jwt(token)
        if result.get("success"):
            return f"Valid: {result['payload']}"
        return f"Invalid: {result.get('error')}"

    def hash_password(self, password: str, **kwargs) -> str:
        result = self.hash_password(password)
        if result.get("success"):
            return f"Hash: {result['hash']}\nSalt: {result['salt']}"
        return f"Error: {result.get('error')}"

    def verify_password(self, password: str, hash_hex: str, salt_hex: str, **kwargs) -> str:
        result = self.verify_password(password, hash_hex, salt_hex)
        if result.get("success"):
            return f"Valid: {result['valid']}"
        return f"Error: {result.get('error')}"

    def role_based_access(self, user_role: str, required_role: str, **kwargs) -> str:
        result = self.role_based_access(user_role, required_role)
        if result.get("success"):
            return f"Allowed: {result['allowed']} (user: {result['user_role']} >= required: {result['required_role']})"
        return f"Error: {result.get('error')}"

    def api_key_vault(self, action: str = "get", key_name: str = "", key_value: str = "", **kwargs) -> str:
        result = self.api_key_vault(action, key_name, key_value)
        if result.get("success"):
            if action == "list":
                return f"Keys: {', '.join(result['keys']) or '(none)'}"
            return result.get("message", f"Value: {result.get('value', '')}")
        return f"Error: {result.get('error')}"

    def rate_limit_check(self, identifier: str, max_requests: int = 100, window_seconds: int = 60, **kwargs) -> str:
        result = self.rate_limit_check(identifier, max_requests, window_seconds)
        if result.get("success"):
            return f"Allowed: {result['allowed']} (current: {result['current']}/{result['limit']})"
        return f"Error: {result.get('error')}"

    def session_revoke(self, session_id: str, **kwargs) -> str:
        result = self.session_revoke(session_id)
        return result.get("message", f"Error: {result.get('error')}")