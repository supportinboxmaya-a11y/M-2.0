#!/usr/bin/env python3
"""Full round-trip test: Audio -> STT -> LLM -> TTS -> Audio"""
import asyncio
import websockets
import json
import base64
import requests
import os

async def test_full_roundtrip():
    # Get auth token
    resp = requests.post('http://localhost:8001/api/v1/auth/login',
        json={'email': 'admin@maya.ai', 'password': 'change-this-password'},
        headers={'Content-Type': 'application/json'})
    token = resp.json()['access_token']
    print(f"Got token: {token[:20]}...")
    
    # First test: text input (already verified)
    print("\n=== Test 1: Text input (bypass STT) ===")
    uri = f"ws://localhost:8001/api/v1/voice/gateway?token={token}"
    async with websockets.connect(uri) as ws:
        msg = await ws.recv()
        data = json.loads(msg)
        print(f"Connected: {data.get('type')}, session: {data.get('session_id')}")
        
        await ws.send(json.dumps({"type": "text", "text": "What is the capital of France?"}))
        
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            print(f"  {data.get('type')}", end="")
            if data.get('type') == 'speaking':
                print(f" - Maya: {data.get('text')[:80]}...")
                audio_b64 = data.get('audio_base64', '')
                if audio_b64:
                    with open('/tmp/test_output1.wav', 'wb') as f:
                        f.write(base64.b64decode(audio_b64))
                    print(f"  Saved audio: {len(audio_b64)} chars")
            elif data.get('type') == 'error':
                print(f" - ERROR: {data.get('message')}")
            if data.get('type') in ('turn_complete', 'error'):
                break
    
    # Test 2: Audio input through STT
    print("\n=== Test 2: Audio input (via STT) ===")
    # First generate test audio using TTS
    print("Generating test audio via TTS...")
    tts_resp = requests.post('http://localhost:8001/api/v1/voice/synthesize/json',
        json={'text': 'What is 5 times 6?'},
        headers={'Authorization': 'Bearer ' + token})
    tts_data = tts_resp.json()
    audio_b64 = tts_data['audio_base64']
    
    # Now send this audio through the gateway
    async with websockets.connect(uri) as ws:
        msg = await ws.recv()
        data = json.loads(msg)
        print(f"Connected: {data.get('type')}, session: {data.get('session_id')}")
        
        # Send audio chunks (simulate streaming)
        audio_bytes = base64.b64decode(audio_b64)
        # Send in chunks
        chunk_size = 3200  # ~100ms at 16kHz
        for i in range(0, len(audio_bytes), chunk_size):
            chunk = audio_bytes[i:i+chunk_size]
            await ws.send(chunk)
            await asyncio.sleep(0.05)  # Small delay between chunks
        
        # Send end signal to trigger STT
        await ws.send(json.dumps({"type": "end"}))
        
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            print(f"  {data.get('type')}", end="")
            if data.get('type') == 'transcript':
                print(f" - STT: {data.get('text')}")
            elif data.get('type') == 'speaking':
                print(f" - Maya: {data.get('text')[:80]}...")
                audio_b64 = data.get('audio_base64', '')
                if audio_b64:
                    with open('/tmp/test_output2.wav', 'wb') as f:
                        f.write(base64.b64decode(audio_b64))
                    print(f"  Saved audio: {len(audio_b64)} chars")
            elif data.get('type') == 'error':
                print(f" - ERROR: {data.get('message')}")
            if data.get('type') in ('turn_complete', 'error'):
                break

    # Verify the TTS output can be transcribed back (STT round-trip)
    print("\n=== Test 3: TTS -> STT verification ===")
    with open('/tmp/test_output1.wav', 'rb') as f:
        test_audio_b64 = base64.b64encode(f.read()).decode()
    
    stt_resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
        json={'audio_base64': test_audio_b64},
        headers={'Authorization': 'Bearer ' + token})
    print(f"STT Status: {stt_resp.status_code}")
    if stt_resp.status_code == 200:
        stt_data = stt_resp.json()
        print(f"Transcript: {stt_data.get('transcript')}")
    
    print("\n=== ALL TESTS COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(test_full_roundtrip())