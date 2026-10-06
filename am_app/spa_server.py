import http.server
import socketserver
import os
import sys

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')
PORT = 9000

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Determine the file path
        path = self.translate_path(self.path)
        if not os.path.exists(path) and not '.' in os.path.basename(self.path):
            # Route does not exist as a physical file/folder and has no extension -> serve index.html for SPA
            self.path = '/index.html'
        return super().do_GET()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
        print(f"Serving SPA from {DIRECTORY} on port {PORT}...")
        sys.stdout.flush()
        httpd.serve_forever()
