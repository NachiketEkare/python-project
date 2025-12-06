########## Stage 1: Builder ##########
FROM python:3.11-alpine3.20 AS builder

RUN apk add --no-cache \
    build-base \
    libffi-dev \
    openssl-dev

WORKDIR /app

COPY requirements.txt .

# Install dependencies WITHOUT uvloop/httptools
RUN pip install --no-cache-dir \
        fastapi==0.110.0 \
        uvicorn==0.29.0 \
        httpx==0.27.0

COPY src ./src


########## Stage 2: Runtime (~45MB) ##########
FROM python:3.11-alpine3.20

# Only runtime libs + curl
RUN apk add --no-cache \
    libffi \
    openssl \
    curl

WORKDIR /app

# Alpine Python site-packages path
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Uvicorn, pip console scripts live here
COPY --from=builder /usr/local/bin /usr/local/bin

# App code
COPY --from=builder /app /app

# Strip unnecessary Python stdlib to save space
RUN rm -rf /usr/lib/python3.11/test \
           /usr/lib/python3.11/ensurepip \
           /usr/lib/python3.11/idlelib \
           /usr/lib/python3.11/tkinter \
           /usr/lib/python3.11/curses \
           /usr/share/man/* \
           /usr/share/doc/*

# Create non-root user
RUN adduser -D appuser
USER appuser

EXPOSE 8000

# curl-based HTTP healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
