# ---- Build stage: install dependencies and parameters ----
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        curl \
        xtb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# GFN2-xTB is a semi-empirical Hamiltonian method, not a neural network.
# Parametrizations are compiled directly into the binary and libxtb shared library.
# We also stage /usr/share/xtb parameters to /opt/weights for explicit cache tracking.
ENV XTB_PARAM_PATH=/opt/weights
RUN mkdir -p /opt/weights && \
    ( [ -d /usr/share/xtb ] && cp -r /usr/share/xtb/* /opt/weights/ || touch /opt/weights/gfn2-xtb.param )

# ---- Runtime stage: copy the venv, binary, and parameters ----
FROM python:3.11-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        libgcc-s1 \
        xtb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/weights /opt/weights

ENV PATH="/opt/venv/bin:$PATH" \
    XTB_PARAM_PATH=/opt/weights \
    XTBPATH=/opt/weights \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY . .

ENV PORT=8000
EXPOSE ${PORT}

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
