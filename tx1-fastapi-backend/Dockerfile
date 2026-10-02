# ---- Build stage: install dependencies and pre-download weights ----
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Pre-download MACE-MP-0 fallback weights into /opt/weights
ENV MACE_CACHE_DIR=/opt/weights
RUN python -c "from mace.calculators import mace_mp; mace_mp(model='small', device='cpu')" && \
    mkdir -p /opt/weights && \
    cp -r /root/.cache/mace/* /opt/weights/

# ---- Runtime stage: copy the venv and the weights, nothing else ----
FROM python:3.11-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/weights /opt/weights

RUN mkdir -p /root/.cache && ln -s /opt/weights /root/.cache/mace

ENV PATH="/opt/venv/bin:$PATH" \
    MACE_CACHE_DIR=/opt/weights \
    TX1_CACHE_DIR=/app/t1x_model_checkpoint.pt \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTORCH_ENABLE_MPS_FALLBACK=1

COPY . .

ENV PORT=8000
EXPOSE ${PORT}

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
