# ---- Maya 2.0 backend image (production-ready) ----
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8000

WORKDIR /app

# Install Python deps first so this layer caches when only app code changes.
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Playwright needs its own browser binary + OS-level dependencies.
RUN playwright install --with-deps chromium

# App code (a .dockerignore keeps storage/, .env, tests, etc. out).
COPY . .

# Create the runtime data dirs and run as a non-root user for safety.
RUN mkdir -p storage workspace && \
    useradd --create-home --uid 10001 maya && \
    chown -R maya:maya /app
USER maya

EXPOSE 8000

# Container-level health check hitting the liveness probe.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request,os,sys; \
u='http://127.0.0.1:'+os.getenv('PORT','8000')+'/health/live'; \
sys.exit(0 if urllib.request.urlopen(u,timeout=4).status==200 else 1)" || exit 1

# Honor $PORT (Render/Heroku set it); default 8000. Multiple workers for prod.
CMD uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000} \
    --workers ${WEB_CONCURRENCY:-2} --timeout-keep-alive 30
