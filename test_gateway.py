#!/usr/bin/env python3
"""Test the Voice Gateway WebSocket end-to-end."""
import asyncio
import websockets
import json
import base64
import requests

async def test_voice_gateway():
    # Get auth token
    resp = requests.post('http://localhost:8001/api/v1/auth/login',
        json={'email': 'admin@maya.ai', 'password': 'change-this-password'},
        headers={'Content-Type': 'application/json'})
    token = resp.json()['access_token']
    print(f"Got token: {token[:20]}...")
    
    # Connect to voice gateway
    uri = f"ws://localhost:8001/api/v1/voice/gateway?token={token}"
    print(f"Connecting to {uri}")
    
    async with websockets.connect(uri) as ws:
        # Wait for connected message
        msg = await ws.recv()
        data = json.loads(msg)
        print(f"Connected: {data}")
        session_id = data.get('session_id')
        
        # Send a text message (bypass STT for testing)
        await ws.send(json.dumps({
            "type": "text",
            "text": "Hello Maya, what is 2 plus 2?"
        }))
        
        # Receive responses
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            print(f"Received: {data.get('type')}")
            
            if data.get('type') == 'speaking':
                print(f"  Maya says: {data.get('text')}")
                # Save audio
                audio_b64 = data.get('audio_base64', '')
                if audio_b64:
                    with open('/tmp/gateway_response.wav', 'wb') as f:
                        f.write(base64.b64decode(audio_b64))
                    print(f"  Saved audio: {len(audio_b64)} chars base64")
            
            if data.get('type') == 'turn_complete':
                print("Turn complete!")
                break
            elif data.get('type') == 'error':
                print(f"Error: {data.get('message')}")
                break
        
        # Test ping/pong
        await ws.send(json.dumps({"type": "ping"}))
        msg = await ws.recv()
        print(f"Ping/Pong: {json.loads(msg)}")
        
        # End session
        await ws.send(json.dumps({"type": "end"}))
        print("Session ended")

if __name__ == "__main__":
    asyncio.run(test_voice_gateway())