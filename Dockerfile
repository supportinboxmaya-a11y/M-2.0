# Maya 2.0 ULTRA - Dockerfile
FROM python:3.11-slim

# Working directory
WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Create storage directories
RUN mkdir -p storage/memory storage/logs storage/backups workspace

# Environment
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV LOG_LEVEL=INFO

# Expose port (for future web UI)
EXPOSE 8000

# Run Maya
CMD ["python", "main.py"]
