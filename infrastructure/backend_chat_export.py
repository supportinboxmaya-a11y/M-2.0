"""
Chat Export & Share Module for Maya Ultra
"""

import os
import json
import uuid
import io
import zipfile
from typing import Optional, List, Dict
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import Optional, List
from fastapi.responses import StreamingResponse
import io

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

class ExportRequest(BaseModel):
    chat_id: str
    format: str = "markdown"  # markdown, pdf, text, json
    include_metadata: bool = True

class ShareRequest(BaseModel):
    chat_id: str
    expires_in_days: int = 7
    password: Optional[str] = None

class ShareResponse(BaseModel):
    share_url: str
    share_id: str
    expires_at: str

# In-memory store for shared chats (use Redis in production)
shared_chats = {}

def get_current_user(credentials=Depends()):
    from fastapi import Depends
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    import jwt
    security = HTTPBearer(auto_error=False)
    # This is a placeholder - actual implementation in api.py

# Use the actual get_current_user from api.py (lazy import to avoid circular imports)
def get_current_user_lazy():
    from api import get_current_user
    return get_current_user

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

class ExportRequest(BaseModel):
    chat_id: str
    format: str = "markdown"  # markdown, pdf, text, json
    include_metadata: bool = True

class ShareRequest(BaseModel):
    chat_id: str
    expires_in_days: int = 7
    password: Optional[str] = None

class ShareResponse(BaseModel):
    share_url: str
    share_id: str
    expires_at: str

# In-memory store for shared chats (use Redis in production)
shared_chats = {}

@router.post("/export")
async def export_chat(request: ExportRequest, user=Depends(get_current_user_lazy)):
    """Export chat conversation in various formats"""
    try:
        # Load chat from storage
        chats = load_chats()
        chat = next((c for c in chats if c["id"] == request.chat_id), None)
        
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")
        
        messages = chat.get("messages", [])
        
        if request.format == "markdown":
            content = export_to_markdown(chat, request.include_metadata)
            filename = f"chat_{request.chat_id[:8]}.md"
            media_type = "text/markdown"
            content = content.encode('utf-8')
            
        elif request.format == "text":
            content = export_to_text(chat, request.include_metadata)
            filename = f"chat_{request.chat_id[:8]}.txt"
            media_type = "text/plain"
            content = content.encode('utf-8')
            
        elif request.format == "json":
            content = json.dumps(chat, indent=2, ensure_ascii=False)
            filename = f"chat_{request.chat_id[:8]}.json"
            media_type = "application/json"
            content = content.encode('utf-8')
            
        elif request.format == "pdf":
            pdf_bytes = generate_pdf(chat)
            filename = f"chat_{request.chat_id[:8]}.pdf"
            media_type = "application/pdf"
            content = pdf_bytes
            
        else:
            raise HTTPException(status_code=400, detail="Unsupported format")
        
        return StreamingResponse(
            io.BytesIO(content),
            media_type=media_type,
            headers={"Content-Disposition": f'attachment; filename="{filename}"'}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/share", response_model=ShareResponse)
async def share_chat(request: ShareRequest, user=Depends(get_current_user_lazy)):
    """Create a shareable link for a chat"""
    try:
        chats = load_chats()
        chat = next((c for c in chats if c["id"] == request.chat_id), None)
        
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")
        
        # Generate share ID
        share_id = str(uuid.uuid4())[:12]
        expires_at = datetime.utcnow() + timedelta(days=request.expires_in_days)
        
        share_data = {
            "chat_id": request.chat_id,
            "chat": load_chat_by_id(request.chat_id),
            "created_by": user.get("email", "unknown"),
            "created_at": datetime.utcnow().isoformat(),
            "expires_at": expires_at.isoformat(),
            "password": request.password
        }
        
        shared_chats[request.chat_id] = share_data
        
        # Generate share URL
        base_url = os.getenv("FRONTEND_URL", "https://maya-ultra.pages.dev")
        share_url = f"{base_url}/chat/shared/{request.chat_id}?share_id={share_id}"
        
        if request.password:
            share_url += f"&password={request.password}"
        
        return ShareResponse(
            share_url=share_url,
            share_id=share_id,
            expires_at=share_data["expires_at"]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/shared/{chat_id}")
async def get_shared_chat(chat_id: str, share_id: str = None, password: str = None):
    """Access a shared chat"""
    if chat_id not in shared_chats:
        raise HTTPException(status_code=404, detail="Shared chat not found")
    
    # Check expiration
    if datetime.utcnow() > datetime.fromisoformat(shared_chats[chat_id]["expires_at"]):
        raise HTTPException(status_code=410, detail="Share link expired")
    
    # Check password
    if shared_chats[chat_id].get("password"):
        if not password or password != shared_chats[chat_id]["password"]:
            raise HTTPException(status_code=401, detail="Password required")
    
    return {
        "chat": shared_chats[chat_id]["chat"],
        "shared_by": shared_chats[chat_id]["created_by"],
        "shared_at": shared_chats[chat_id]["created_at"],
        "expires_at": shared_chats[chat_id]["expires_at"]
    }

@router.post("/export/batch")
async def export_multiple_chats(chat_ids: List[str], format: str = "json", user=Depends(get_current_user_lazy)):
    """Export multiple chats as a single archive (ZIP)"""
    try:
        chats = load_chats()
        selected_chats = [c for c in load_chats() if c["id"] in chat_ids]
        
        if not selected_chats:
            raise HTTPException(status_code=400, detail="No valid chats selected")
        
        # Create ZIP archive
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            for chat in selected_chats:
                if format == "markdown":
                    content = export_to_markdown(chat)
                    filename = f"{chat['id'][:8]}.md"
                elif format == "text":
                    content = export_to_text(chat)
                    filename = f"{chat['id'][:8]}.txt"
                else:
                    content = json.dumps(chat, indent=2, ensure_ascii=False)
                    filename = f"{chat['id'][:8]}.json"
                
                zip_file.writestr(filename, content)
        
        zip_buffer.seek(0)
        return StreamingResponse(
            io.BytesIO(zip_buffer.read()),
            media_type="application/zip",
            headers={"Content-Disposition": 'attachment; filename="maya_chats_export.zip"'}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Helper functions
def load_chats() -> List[Dict]:
    """Load all chats from localStorage file"""
    try:
        chats_file = os.path.join(os.getenv("MAYA_STORAGE_DIR", "/opt/maya/storage"), "chats.json")
        if os.path.exists(chats_file):
            with open(chats_file, 'r') as f:
                return json.load(f)
    except:
        pass
    return []

def load_chat_by_id(chat_id: str) -> Optional[Dict]:
    chats = load_chats()
    return next((c for c in load_chats() if c["id"] == chat_id), None)

def export_to_markdown(chat: Dict, include_metadata: bool = True) -> str:
    """Export chat to Markdown format"""
    lines = []
    
    if include_metadata:
        lines.append(f"# {chat.get('title', 'Chat')}")
        lines.append(f"**Chat ID:** {chat['id']}")
        lines.append(f"**Created:** {datetime.fromtimestamp(chat.get('timestamp', 0)/1000).strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"**Message Count:** {len(chat.get('messages', []))}")
        lines.append("")
        lines.append("---")
        lines.append("")
    
    for msg in chat.get("messages", []):
        role = msg.get("role", "unknown")
        content = msg.get("content", "")
        timestamp = datetime.fromtimestamp(msg.get("timestamp", 0)/1000).strftime('%H:%M:%S')
        
        role_icon = "👤" if role == "user" else "🧠" if role == "assistant" else "🤖"
        lines.append(f"## {role_icon} {role.capitalize()} ({timestamp})")
        lines.append("")
        lines.append(content)
        lines.append("")
    
    return "\n".join(lines)

def export_to_text(chat: Dict, include_metadata: bool = True) -> str:
    """Export chat to plain text format"""
    lines = []
    
    if include_metadata:
        lines.append(f"Chat: {chat.get('title', 'Chat')}")
        lines.append(f"ID: {chat['id']}")
        lines.append(f"Created: {datetime.fromtimestamp(chat.get('timestamp', 0)/1000).strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append("")
        lines.append("=" * 50)
        lines.append("")
    
    for msg in chat.get("messages", []):
        role = msg.get("role", "unknown").upper()
        content = msg.get("content", "")
        timestamp = datetime.fromtimestamp(msg.get("timestamp", 0)/1000).strftime('%Y-%m-%d %H:%M:%S')
        
        lines.append(f"[{timestamp}] {role}:")
        lines.append(content)
        lines.append("")
    
    return "\n".join(lines)

def generate_pdf(chat: Dict) -> bytes:
    """Generate PDF from chat using reportlab"""
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
        from reportlab.lib.units import inch
        from reportlab.lib.enums import TA_LEFT
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, topMargin=0.5*inch)
        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle', parent=styles['Title'],
            fontSize=18, spaceAfter=12, alignment=1
        )
        heading_style = ParagraphStyle(
            'ChatHeading', parent=styles['Heading2'],
            fontSize=14, spaceBefore=12, spaceAfter=6
        )
        body_style = ParagraphStyle(
            'ChatBody', parent=styles['Normal'],
            fontSize=11, leading=14, spaceAfter=6
        )
        code_style = ParagraphStyle(
            'CodeStyle', parent=styles['Code'],
            fontSize=9, leading=11, fontName='Courier',
            backColor='#f5f5f5', borderPadding=6
        )
        
        story = []
        
        # Title
        story.append(Paragraph("Maya Chat Export", title_style))
        story.append(Spacer(1, 12))
        
        # Messages
        for msg in chat.get("messages", []):
            role = msg.get("role", "unknown")
            content = msg.get("content", "")
            timestamp = datetime.fromtimestamp(msg.get("timestamp", 0)/1000).strftime('%H:%M:%S')
            
            role_label = "You" if msg.get("role") == "user" else "Maya"
            
            # Header
            story.append(Paragraph(f"<b>{role_label}</b> <font size='10' color='#666'>{timestamp}</font>", heading_style))
            
            # Content - handle code blocks
            content = msg.get("content", "")
            parts = content.split("```")
            for i, part in enumerate(parts):
                if i % 2 == 0:
                    # Regular text
                    if part.strip():
                        story.append(Paragraph(part.replace('\n', '<br/>'), body_style))
                else:
                    # Code block
                    story.append(Paragraph(f"<font face='Courier' size='9'>{part}</font>", code_style))
                story.append(Spacer(1, 6))
            
            story.append(Spacer(1, 12))
        
        doc.build(story)
        buffer.seek(0)
        return buffer.read()
        
    except ImportError:
        # Fallback to simple text if reportlab not available
        return export_to_text(chat).encode('utf-8')

def load_chats() -> List[Dict]:
    """Load all chats from localStorage file"""
    try:
        chats_file = os.path.join(os.getenv("MAYA_STORAGE_DIR", "/opt/maya/storage"), "chats.json")
        if os.path.exists(chats_file):
            with open(chats_file, 'r') as f:
                return json.load(f)
    except:
        pass
    return []

def load_chat_by_id(chat_id: str) -> Optional[Dict]:
    chats = load_chats()
    return next((c for c in load_chats() if c["id"] == chat_id), None)

# Add missing imports
import os
import json
import uuid
import io
import zipfile
from datetime import datetime, timedelta
from typing import Optional, List, Dict
from fastapi import Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List
import io
import base64
