FROM python:3.12-alpine

WORKDIR /app

COPY server.py /app/server.py
COPY app.py /app/app.py

ENV SERVICE_NAME=notification-worker
ENV PORT=8080

EXPOSE 8080

CMD ["python", "app.py"]
