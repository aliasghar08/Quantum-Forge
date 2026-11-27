FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    PROJECT_ID=quantom-forge \
    SEEDER_BATCH_SIZE=200 \
    SEEDER_WORKERS=4 \
    SEEDER_CATEGORY_MODE=all

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY seed_massive_firebase.py .
COPY search_tokenizer.py .
COPY assets/ ./assets/
COPY server.py .

EXPOSE 8080

CMD ["python3", "server.py"]
