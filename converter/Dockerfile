FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV HOME=/tmp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libreoffice \
       fonts-dejavu \
       fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD exec gunicorn \
    --bind :${PORT:-8080} \
    --workers 1 \
    --threads 2 \
    --timeout 240 \
    app:app
