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

# Preload TorchANI ANI-2x parameters.
# While the model architecture is in the torchani package, ANI-2x parameter files
# are fetched on first instantiation and cached inside the venv package resources
# or ~/.local/torchani/. Running this during build guarantees they are baked into
# the image so runtime starts with zero network activity.
ENV ANI_CACHE_DIR=/opt/weights
RUN python -c "import torchani; torchani.models.ANI2x()" && \
    mkdir -p /opt/weights && \
    ( [ -d /root/.local/torchani ] && cp -r /root/.local/torchani/* /opt/weights/ || true )

# ---- Runtime stage: copy the venv and the weights, nothing else ----
FROM python:3.11-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/weights /opt/weights

RUN mkdir -p /root/.local && ln -s /opt/weights /root/.local/torchani

ENV PATH="/opt/venv/bin:$PATH" \
    ANI_CACHE_DIR=/opt/weights \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTORCH_ENABLE_MPS_FALLBACK=1

COPY . .

ENV PORT=8000
EXPOSE ${PORT}

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
