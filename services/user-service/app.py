from server import Handler, HTTPServer, SERVICE_NAME, PORT, json_response

class UserServiceHandler(Handler):
    def route(self, path):
        if path == "/users":
            return json_response(self, 200, {
                "service": SERVICE_NAME,
                "users": [
                    {"id": 1, "name": "Danila"},
                    {"id": 2, "name": "Demo User"}
                ]
            })
        return super().route(path)

if __name__ == "__main__":
    print(f"Starting {SERVICE_NAME} on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), UserServiceHandler).serve_forever()
