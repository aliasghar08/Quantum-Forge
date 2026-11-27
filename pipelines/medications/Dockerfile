FROM python:3.10-slim

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libxrender1 libxext6 sqlite3 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir rdkit ase numpy requests google-auth google-cloud-firestore

COPY pipelines/medications/ ./pipelines/medications/

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/pipelines/medications
CMD ["python3", "pipelines/medications/medicine_harvester.py"]
