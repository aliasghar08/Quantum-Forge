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

# Preload CHGNet pretrained model.
# CHGNet bundles its default pretrained model (0.3.0) inside chgnet/pretrained/
# within the installed package. Pre-loading verifies the model and stages the
# weights into /opt/weights for explicit cache control and provenance.
ENV CHGNET_CACHE_DIR=/opt/weights
RUN python -c "from chgnet.model import CHGNet; CHGNet.load(use_device='cpu')" && \
    mkdir -p /opt/weights && \
    python -c "import chgnet, shutil, os; shutil.copytree(os.path.join(os.path.dirname(chgnet.__file__), 'pretrained'), '/opt/weights/pretrained', dirs_exist_ok=True)"

# ---- Runtime stage: copy the venv and the weights, nothing else ----
FROM python:3.11-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/weights /opt/weights

ENV PATH="/opt/venv/bin:$PATH" \
    CHGNET_CACHE_DIR=/opt/weights \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTORCH_ENABLE_MPS_FALLBACK=1

COPY . .

ENV PORT=8000
EXPOSE ${PORT}

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
