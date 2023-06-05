from http.server import BaseHTTPRequestHandler, HTTPServer
import base64 

hostName = "localhost"
serverPort = 8080

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "video/rgv")
        self.end_headers()
        with open("video.rgv", "rb") as f:
            self.wfile.write(base64.b64encode(f.read()))

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
