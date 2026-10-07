FROM python:3.12-slim

WORKDIR /app

# Install system deps if you need them (e.g. build tools for RDKit)
# RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Cloud Run injects $PORT automatically; fall back to 8080 locally
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}
