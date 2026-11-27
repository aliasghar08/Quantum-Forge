FROM python:3.10-slim

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libxrender1 libxext6 sqlite3 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir rdkit ase numpy requests google-auth google-cloud-firestore

COPY pipelines/reactions/ ./pipelines/reactions/

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/pipelines/reactions
CMD ["python3", "pipelines/reactions/reaction_literature_harvester.py"]
