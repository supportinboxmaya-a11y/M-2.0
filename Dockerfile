FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Playwright needs its own browser binary + OS-level dependencies
RUN playwright install --with-deps chromium

COPY . .

CMD uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}
