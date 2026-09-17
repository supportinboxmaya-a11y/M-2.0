import os
import json
import requests
from typing import List, Dict, Optional, Generator
from llm.providers.local_llm import LocalLLMProvider

class LocalFastLLMProvider(LocalLLMProvider):
    def __init__(self):
        super().__init__()
        self.default_model = os.environ.get("LOCAL_MODEL_FAST", "llama3.2:3b-instruct-q4_k_m")
        self.timeout = 120.0
