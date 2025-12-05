########## Stage 1: Build ##########
FROM python:3.11-slim AS builder

WORKDIR /app

# Install dependencies into a local user directory
COPY app/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt


########## Stage 2: Final Runtime Image ##########
FROM python:3.11-slim

# Create a non-root user
RUN useradd -m appuser
USER appuser

WORKDIR /app

# Copy installed packages from builder layer
COPY --from=builder /root/.local /home/appuser/.local

# Add Local Python packages to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application code
COPY app/ .

# Healthcheck for ECS / Docker
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Start FastAPI app with Uvicorn (production settings)
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
