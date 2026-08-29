#!/usr/bin/env python3
import base64
import requests
import json
import os
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

# Transcribe audio
with open('/tmp/test_audio.wav', 'rb') as f:
    audio_b64 = base64.b64encode(f.read()).decode()

resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
    json={'audio_base64': audio_b64},
    headers={'Authorization': 'Bearer ' + token})

print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))