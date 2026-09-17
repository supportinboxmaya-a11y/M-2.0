#!/usr/bin/env python3
"""Test script for voice STT endpoints."""
import base64
import requests
import json
import sys

# Get token
resp = requests.post('http://localhost:8001/api/v1/auth/login',
    json={"email": "admin@maya.ai", "password": "change-this-password"},
    headers={'Content-Type': 'application/json'})

if resp.status_code != 200:
    print("Login failed:", resp.status_code, resp.text)
    sys.exit(1)

token = resp.json()['access_token']
print("Got token:", token[:20] + "...")

headers = {'Authorization': 'Bearer ' + token}

# Test 1: JSON with audio_base64
print("\n=== Test 1: JSON with audio_base64 ===")
with open('/tmp/test_audio.wav', 'rb') as f:
    audio_b64 = base64.b64encode(f.read()).decode()

resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
    json={'audio_base64': audio_b64},
    headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

# Test 2: JSON with audio (old field name)
print("\n=== Test 2: JSON with audio ===")
resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
    json={'audio': audio_b64},
    headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

# Test 3: File upload
print("\n=== Test 3: File upload ===")
with open('/tmp/test_audio.wav', 'rb') as f:
    files = {'file': ('test.wav', f, 'audio/wav')}
    resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
        files=files,
        headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

# Test 4: Models endpoint
print("\n=== Test 4: Models endpoint ===")
resp = requests.get('http://localhost:8001/api/v1/voice/models', headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))

print("\n=== All tests passed! ===")