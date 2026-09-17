import base64
import requests
import os

TOKEN = os.environ.get('MAYA_TOKEN', '')
if not TOKEN:
    print("No token provided")
    exit(1)

with open('/tmp/test_audio.wav', 'rb') as f:
    audio_b64 = base64.b64encode(f.read()).decode()

resp = requests.post('http://localhost:8001/api/v1/voice/transcribe',
    json={'audio': audio_b64},
    headers={'Authorization': 'Bearer ' + TOKEN})
print(resp.status_code)
print(resp.json())