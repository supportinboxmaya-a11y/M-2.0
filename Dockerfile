# Maya 2.0 ULTRA - Dockerfile (Railway/Render ready)
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p storage/memory storage/logs storage/backups workspace

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV LOG_LEVEL=INFO

# Railway provides PORT env var; default 8000
EXPOSE 8000

# Run the FastAPI web server (NOT main.py CLI)
CMD uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}
