# syntax=docker/dockerfile:1.4
FROM python:3.11-slim as builder

WORKDIR /app

# Instala dependencias del sistema necesarias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 \
        libgl1-mesa-glx \
        gcc \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Instala dependencias de Python
RUN pip install --user --no-cache-dir -r requirements.txt


FROM python:3.11-slim as runtime

WORKDIR /app

# Instala runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 \
        libgl1-mesa-glx \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Copia las dependencias instaladas
COPY --from=builder /root/.local /root/.local
COPY . .

# Asegura que las dependencias estén en el PATH
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

EXPOSE ${PORT}

# Comando optimizado para producción
CMD ["uvicorn", "challenge.api:app", "--host", "0.0.0.0", "--port", "8080", "--no-access-log"]