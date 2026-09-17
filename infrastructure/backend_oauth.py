"""
OAuth / Social Login Module for Maya Ultra
Supports Google, GitHub, and Microsoft OAuth
"""

import os
import httpx
import jwt
import uuid
import time
import urllib.parse
from datetime import datetime, timedelta
from typing import Optional, Dict
from fastapi import APIRouter, HTTPException, Depends, Request, Query, Response
from pydantic import BaseModel
from typing import Optional, Dict
from fastapi import Depends, HTTPException, Query, Request, Response
from fastapi.responses import RedirectResponse
import urllib.parse

router = APIRouter(prefix="/api/v1/auth/oauth", tags=["oauth"])

# OAuth provider configurations
OAUTH_PROVIDERS = {
    "google": {
        "name": "Google",
        "client_id": os.getenv("GOOGLE_CLIENT_ID", ""),
        "client_secret": os.getenv("GOOGLE_CLIENT_SECRET", ""),
        "authorize_url": "https://accounts.google.com/o/oauth2/v2/auth",
        "token_url": "https://oauth2.googleapis.com/token",
        "userinfo_url": "https://www.googleapis.com/oauth2/v2/userinfo",
        "scopes": ["openid", "email", "profile"],
        "icon": "🌐",
        "color": "#4285F4"
    },
    "github": {
        "name": "GitHub",
        "client_id": os.getenv("GITHUB_CLIENT_ID", ""),
        "client_secret": os.getenv("GITHUB_CLIENT_SECRET", ""),
        "authorize_url": "https://github.com/login/oauth/authorize",
        "token_url": "https://github.com/login/oauth/access_token",
        "userinfo_url": "https://api.github.com/user",
        "scopes": ["read:user", "user:email"],
        "icon": "🐙",
        "color": "#333333"
    },
    "microsoft": {
        "name": "Microsoft",
        "client_id": os.getenv("MICROSOFT_CLIENT_ID", ""),
        "client_secret": os.getenv("MICROSOFT_CLIENT_SECRET", ""),
        "authorize_url": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
        "token_url": "https://login.microsoftonline.com/common/oauth2/v2.0/token",
        "userinfo_url": "https://graph.microsoft.com/v1.0/me",
        "scopes": ["openid", "email", "profile", "User.Read"],
        "icon": "🪟",
        "color": "#0078D4"
    }
}

router = APIRouter(prefix="/api/v1/auth/oauth", tags=["oauth"])

class OAuthState(BaseModel):
    provider: str
    redirect_url: Optional[str] = None
    state: str
    created_at: float

# In-memory state store (use Redis in production)
oauth_states = {}

class OAuthCallbackRequest(BaseModel):
    code: str
    state: str
    provider: str

class OAuthTokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    refresh_token: Optional[str] = None
    expires_at: int

class UserInfoResponse(BaseModel):
    provider: str
    provider_user_id: str
    email: str
    name: str
    avatar_url: Optional[str] = None
    raw_data: Dict

def generate_oauth_state(provider: str, redirect_url: str = None) -> str:
    """Generate and store OAuth state"""
    state = str(uuid.uuid4())
    oauth_states[state] = {
        "provider": provider,
        "redirect_url": redirect_url,
        "created_at": time.time()
    }
    return state

def verify_oauth_state(state: str) -> Optional[Dict]:
    """Verify and consume OAuth state"""
    if state not in oauth_states:
        return None
    state_data = oauth_states.pop(state)
    # Check expiry (10 minutes)
    if time.time() - state_data["created_at"] > 600:
        return None
    return state_data

@router.get("/providers")
async def list_oauth_providers():
    """List available OAuth providers"""
    providers = []
    for key, config in OAUTH_PROVIDERS.items():
        if config["client_id"] and config["client_secret"]:
            providers.append({
                "id": key,
                "name": config["name"],
                "icon": config.get("icon", ""),
                "color": config.get("color", ""),
                "configured": True
            })
        else:
            providers.append({
                "id": key,
                "name": config["name"],
                "icon": config.get("icon", ""),
                "color": config.get("color", ""),
                "configured": False
            })
    return {"providers": providers}

@router.get("/login/{provider}")
async def oauth_login(provider: str, redirect_url: str = None):
    """Initiate OAuth login flow"""
    if provider not in OAUTH_PROVIDERS:
        raise HTTPException(status_code=400, detail="Unsupported provider")
    
    provider_config = OAUTH_PROVIDERS[provider]
    
    if not provider_config["client_id"] or not provider_config["client_secret"]:
        raise HTTPException(status_code=501, detail=f"{provider_config['name']} OAuth not configured")
    
    # Generate state
    state = generate_oauth_state(provider, redirect_url)
    
    # Build authorization URL
    params = {
        "client_id": OAUTH_PROVIDERS[provider]["client_id"],
        "redirect_uri": f"{os.getenv('BACKEND_URL', 'http://130.210.46.182:8000')}/api/v1/auth/oauth/callback",
        "scope": " ".join(provider_config["scopes"]),
        "response_type": "code",
        "state": state,
        "access_type": "offline",  # For refresh token
        "prompt": "consent"  # Force consent screen for Google
    }
    
    auth_url = f"{provider_config['authorize_url']}?{urllib.parse.urlencode(params)}"
    
    # For API usage, return the URL instead of redirecting
    return {"auth_url": auth_url, "state": state}

@router.get("/callback")
async def oauth_callback(
    code: str = Query(...),
    state: str = Query(...),
    error: str = None,
    error_description: str = None
):
    """Handle OAuth callback"""
    
    if error:
        raise HTTPException(status_code=400, detail=error_description or error)
    
    # Verify state
    state_data = verify_oauth_state(state)
    if not state_data:
        raise HTTPException(status_code=400, detail="Invalid or expired OAuth state")
    
    provider = state_data["provider"]
    redirect_url = state_data.get("redirect_url")
    
    provider_config = OAUTH_PROVIDERS[provider]
    
    # Exchange code for tokens
    token_url = provider_config["token_url"]
    token_data = {
        "client_id": provider_config["client_id"],
        "client_secret": provider_config["client_secret"],
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": f"{os.getenv('BACKEND_URL', 'http://130.210.46.182:8000')}/api/v1/auth/oauth/callback"
    }
    
    async with httpx.AsyncClient() as client:
        try:
            token_response = await client.post(
                token_url,
                data=token_data,
                headers={"Accept": "application/json"},
                timeout=30.0
            )
            
            if token_response.status_code != 200:
                logger.error(f"Token exchange failed: {token_response.text}")
                raise HTTPException(status_code=400, detail="Failed to exchange code for token")
            
            token_data = token_response.json()
            
        except Exception as e:
            logger.error(f"Token exchange error: {e}")
            raise HTTPException(status_code=500, detail="Token exchange failed")
    
    # Get user info
    access_token = token_data["access_token"]
    refresh_token = token_data.get("refresh_token")
    expires_in = token_data.get("expires_in", 3600)
    
    userinfo_url = OAUTH_PROVIDERS[provider]["userinfo_url"]
    
    async with httpx.AsyncClient() as client:
        try:
            headers = {"Authorization": f"Bearer {access_token}"}
            if provider == "github":
                headers["Accept"] = "application/vnd.github.v3+json"
            
            userinfo_response = await client.get(
                userinfo_url,
                headers=headers,
                timeout=10.0
            )
            
            if userinfo_response.status_code != 200:
                logger.error(f"Userinfo fetch failed: {userinfo_response.text}")
                raise HTTPException(status_code=400, detail="Failed to fetch user info")
            
            user_data = userinfo_response.json()
            
        except Exception as e:
            logger.error(f"Userinfo fetch error: {e}")
            raise HTTPException(status_code=500, detail="Failed to fetch user info")
    
    # Normalize user data
    user_info = normalize_user_info(provider, user_data)
    
    # Create or get user
    user = await get_or_create_oauth_user(provider, user_info)
    
    # Create JWT token
    access_token = create_token(user["email"], user["uid"], user.get("role", "user"))
    
    # Calculate expiry
    expires_at = int(time.time()) + 60 * 60 * 24 * 7  # 7 days
    
    # Redirect to frontend with token
    frontend_url = os.getenv("FRONTEND_URL", "https://maya-ultra.pages.dev")
    redirect_url = f"{os.getenv('FRONTEND_URL', 'https://maya-ultra.pages.dev')}/auth/callback?token={access_token}"
    
    # For API clients, return JSON
    accept = "application/json"
    # Check if request wants JSON
    # For now, redirect to frontend
    response = RedirectResponse(url=redirect_url)
    
    # Set secure cookie
    response.set_cookie(
        key="maya_token",
        value=access_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=60*60*24*7  # 7 days
    )
    
    return response

def normalize_user_info(provider: str, data: Dict) -> Dict:
    """Normalize user info from different providers"""
    if provider == "google":
        return {
            "provider": "google",
            "provider_user_id": data.get("id"),
            "email": data.get("email"),
            "name": data.get("name"),
            "avatar_url": data.get("picture"),
            "email_verified": data.get("verified_email", False),
            "raw_data": data
        }
    elif provider == "github":
        # GitHub doesn't always return email in user endpoint
        email = data.get("email")
        if not email:
            # Fetch emails separately
            pass
        return {
            "provider": "github",
            "provider_user_id": str(data.get("id")),
            "email": data.get("email") or f"{data.get('login')}@users.noreply.github.com",
            "name": data.get("name") or data.get("login"),
            "avatar_url": data.get("avatar_url"),
            "email_verified": True,  # GitHub emails are verified
            "raw_data": data
        }
    elif provider == "microsoft":
        return {
            "provider": "microsoft",
            "provider_user_id": data.get("id"),
            "email": data.get("mail") or data.get("userPrincipalName"),
            "name": data.get("displayName"),
            "avatar_url": None,  # Would need separate Graph API call
            "email_verified": True,
            "raw_data": data
        }
    return {}

async def get_or_create_oauth_user(provider: str, user_info: Dict) -> Dict:
    """Get existing user or create new one from OAuth info"""
    # In a real implementation, check database for existing user
    # For now, create a user object
    
    email = user_info.get("email")
    if not email:
        # Generate a placeholder email for providers that don't provide email
        email = f"{user_info['provider']}_{user_info['provider_user_id']}@oauth.maya.local"
    
    uid = f"{user_info['provider']}_{user_info['provider_user_id']}"
    
    return {
        "uid": uid,
        "email": user_info["email"],
        "name": user_info.get("name") or user_info.get("email", "").split("@")[0],
        "provider": provider,
        "provider_user_id": user_info["provider_user_id"],
        "avatar_url": user_info.get("avatar_url"),
        "role": "user",
        "oauth_provider": user_info["provider"]
    }

def create_token(email: str, uid: str = "", role: str = "user") -> str:
    """Create JWT token"""
    payload = {
        "sub": email,
        "uid": uid,
        "role": role,
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# Add missing imports
import time
import os
import httpx
from datetime import datetime, timedelta
from fastapi import Depends
