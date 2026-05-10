from server import Handler, HTTPServer, SERVICE_NAME, PORT, json_response

class NotificationWorkerHandler(Handler):
    def route(self, path):
        if path == "/work":
            return json_response(self, 200, {
                "service": SERVICE_NAME,
                "status": "worker loop is available for demo checks"
            })
        return super().route(path)

if __name__ == "__main__":
    print(f"Starting {SERVICE_NAME} on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), NotificationWorkerHandler).serve_forever()
