FROM python:3.12-alpine

RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app

WORKDIR /app

COPY --chown=10001:10001 server.py /app/server.py
COPY --chown=10001:10001 app.py /app/app.py

ENV SERVICE_NAME=user-service
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

USER 10001

CMD ["python", "app.py"]
