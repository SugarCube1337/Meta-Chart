from server import Handler, HTTPServer, SERVICE_NAME, PORT, os, json_response

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "")
ORDER_SERVICE_URL = os.getenv("ORDER_SERVICE_URL", "")

class ApiGatewayHandler(Handler):
    def route(self, path):
        if path == "/" or path == "/dependencies":
            return json_response(self, 200, {
                "service": SERVICE_NAME,
                "message": "API gateway is running",
                "dependencies": {
                    "USER_SERVICE_URL": USER_SERVICE_URL,
                    "ORDER_SERVICE_URL": ORDER_SERVICE_URL
                }
            })
        return super().route(path)

if __name__ == "__main__":
    print(f"Starting {SERVICE_NAME} on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), ApiGatewayHandler).serve_forever()
