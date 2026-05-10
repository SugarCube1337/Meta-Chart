from server import Handler, HTTPServer, SERVICE_NAME, PORT, os

API_GATEWAY_URL = os.getenv("API_GATEWAY_URL", "http://api-gateway:80")

class FrontendHandler(Handler):
    def route(self, path):
        if path == "/":
            html = f"""<!doctype html>
<html>
  <head><meta charset="utf-8"><title>VKR Meta-Chart Demo</title></head>
  <body>
    <h1>VKR Meta-Chart Demo</h1>
    <p>Service: {SERVICE_NAME}</p>
    <p>API gateway URL: {API_GATEWAY_URL}</p>
  </body>
</html>
"""
            body = html.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        return super().route(path)

if __name__ == "__main__":
    print(f"Starting {SERVICE_NAME} on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), FrontendHandler).serve_forever()
