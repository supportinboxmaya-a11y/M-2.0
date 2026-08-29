#!/usr/bin/env python3
"""Quick test for models endpoint."""
import requests
import json

resp = requests.post('http://localhost:8001/api/v1/auth/login',
    json={"email": "admin@maya.ai", "password": "change-this-password"},
    headers={'Content-Type': 'application/json'})

token = resp.json()['access_token']
headers = {'Authorization': 'Bearer ' + token}

resp = requests.get('http://localhost:8001/api/v1/voice/models', headers=headers)
print("Status:", resp.status_code)
print("Response:", json.dumps(resp.json(), indent=2))