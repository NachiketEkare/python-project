########## Stage 1: Build ##########
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build deps (uvicorn, httpx, etc may need C libs)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

COPY src ./src


########## Stage 2: Runtime (Distroless) ##########
FROM gcr.io/distroless/python3

WORKDIR /app

# Copy installed python packages
COPY --from=builder /install /usr/local

# Copy application source
COPY --from=builder /app/src ./src

EXPOSE 8000

# Distroless has no shell, wget, curl — use Python healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD ["python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]

# Start FastAPI app
CMD ["-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
