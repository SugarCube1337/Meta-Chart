from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import json
import os
import time

SERVICE_NAME = os.getenv("SERVICE_NAME", "service")
PORT = int(os.getenv("PORT", "8080"))
STARTED_AT = time.time()

def json_response(handler, code, payload):
    body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)

def text_response(handler, code, payload, content_type="text/plain; charset=utf-8"):
    body = payload.encode("utf-8")
    handler.send_response(code)
    handler.send_header("Content-Type", content_type)
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[{SERVICE_NAME}] {self.address_string()} - {fmt % args}")

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/health":
            return json_response(self, 200, {
                "status": "ok",
                "service": SERVICE_NAME,
                "uptimeSeconds": int(time.time() - STARTED_AT)
            })

        if path == "/ready":
            return json_response(self, 200, {
                "status": "ready",
                "service": SERVICE_NAME
            })

        if path == "/metrics":
            metric_name = SERVICE_NAME.replace("-", "_")
            return text_response(self, 200,
                f"# HELP {metric_name}_up Service availability flag\n"
                f"# TYPE {metric_name}_up gauge\n"
                f"{metric_name}_up 1\n"
            )

        return self.route(path)

    def route(self, path):
        return json_response(self, 200, {
            "service": SERVICE_NAME,
            "path": path,
            "message": f"{SERVICE_NAME} is running"
        })
