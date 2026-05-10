from server import Handler, HTTPServer, SERVICE_NAME, PORT, os, json_response

NOTIFICATION_WORKER_URL = os.getenv("NOTIFICATION_WORKER_URL", "")

class OrderServiceHandler(Handler):
    def route(self, path):
        if path == "/orders":
            return json_response(self, 200, {
                "service": SERVICE_NAME,
                "orders": [
                    {"id": 1001, "status": "created"},
                    {"id": 1002, "status": "paid"}
                ],
                "NOTIFICATION_WORKER_URL": NOTIFICATION_WORKER_URL
            })
        if path == "/dependencies":
            return json_response(self, 200, {
                "NOTIFICATION_WORKER_URL": NOTIFICATION_WORKER_URL
            })
        return super().route(path)

if __name__ == "__main__":
    print(f"Starting {SERVICE_NAME} on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), OrderServiceHandler).serve_forever()
