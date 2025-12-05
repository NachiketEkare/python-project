########## Stage 1: Build ##########
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies (only for this stage)
RUN apk add --no-cache build-base

COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt


########## Stage 2: Runtime (Distroless) ##########
FROM gcr.io/distroless/python3

# Create non-root user
RUN adduser -D appuser
USER appuser

WORKDIR /app

# Copy installed python packages
COPY --from=builder /install /usr/local

# Copy source code
COPY src/ ./src/

EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget -qO- http://localhost:8000/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
