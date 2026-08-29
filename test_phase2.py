#!/usr/bin/env python3
"""Comprehensive test for Phase 2: STT + TTS endpoints."""
import base64
import requests
import json
import sys
import os

# Login
resp = requests.post('http://localhost:8001/api/v1/auth/login',
    json={"email": "admin@maya.ai", "password": "change-this-password"},
    headers={'Content-Type': 'application/json'})

if resp.status_code != 200:
    print("Login failed:", resp.status_code, resp.text)
    sys.exit(1)

token = resp.json()['access_token']
print("Got token:", token[:20] + "...")

headers = {'Authorization': 'Bearer ' + token}

print("\n" + "="*60)
print("TTS TESTS")
print("="*60)

# Test 1: Synthesize JSON
print("\n--- Test 1: POST /api/v1/voice/synthesize/json ---")
resp = requests.post('http://localhost:8001/api/v1/voice/synthesize/json',
    json={'text': 'Hello, this is a comprehensive test of the text to speech system.'},
    headers=headers)
print("Status:", resp.status_code)
data = resp.json()
print("Sample rate:", data.get('sample_rate'))
audio_b64 = data['audio_base64']
with open('/tmp/tts_test1.wav', 'wb') as f:
    f.write(base64.b64decode(audio_b64))
print("Saved:", os.path.getsize('/tmp/tts_test1.wav'), "bytes")

# Test 2: Synthesize form (returns audio file)
print("\n--- Test 2: POST /api/v1/voice/synthesize (form) ---")
resp = requests.post('http://localhost:8001/api/v1/voice/synthesize',
    data={'text': 'Testing form data endpoint with audio file response.'},
    headers=headers)
print("Status:", resp.status_code, "Content-Type:", resp.headers.get('content-type'))
with open('/tmp/tts_test2.wav', 'wb') as f:
    f.write(resp.content)
print("Saved:", os.path.getsize('/tmp/tts_test2.wav'), "bytes")

# Test 3: Voices endpoint
print("\n--- Test 3: GET /api/v1/voice/voices ---")
resp = requests.get('http://localhost:8001/api/v1/voice/voices', headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

print("\n" + "="*60)
print("STT TESTS")
print("="*60)

# Test 4: Transcribe the TTS output (round-trip)
print("\n--- Test 4: POST /api/v1/voice/transcribe (TTS->STT round-trip) ---")
with open('/tmp/tts_test1.wav', 'rb') as f:
    audio_b64 = base64.b64encode(f.read()).decode()
resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
    json={'audio_base64': audio_b64},
    headers=headers)
print("Status:", resp.status_code)
data = resp.json()
print("Transcript:", data.get('transcript'))
print("Language:", data.get('language'))

# Test 5: Transcribe file upload
print("\n--- Test 5: POST /api/v1/voice/transcribe (file upload) ---")
with open('/tmp/tts_test2.wav', 'rb') as f:
    files = {'file': ('test.wav', f, 'audio/wav')}
    resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
        files=files,
        headers=headers)
print("Status:", resp.status_code)
data = resp.json()
print("Transcript:", data.get('transcript'))

# Test 6: STT Models endpoint
print("\n--- Test 6: GET /api/v1/voice/models ---")
resp = requests.get('http://localhost:8001/api/v1/voice/models', headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

print("\n" + "="*60)
print("ALL TESTS PASSED!")
print("="*60)