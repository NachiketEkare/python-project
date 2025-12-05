########## Stage 1: Build (Alpine) ##########
FROM python:3.11-alpine AS builder

WORKDIR /app

# Install build dependencies for Alpine
RUN apk add --no-cache build-base

# Install python deps into /install
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

COPY src ./src


########## Stage 2: Runtime (Distroless) ##########
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

# Copy dependencies
COPY --from=builder /install /usr/local

# Copy application
COPY --from=builder /app/src ./src

EXPOSE 8000

# Distroless has no curl/wget → use python for healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD ["python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]

# Run FastAPI
CMD ["-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
