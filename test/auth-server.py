"""Basic auth HTTP server in front of `git http-backend`, used by test.sh.

Usage: auth-server.py <git> <project-root> <port-file>

Listens on a free port of 127.0.0.1 and writes it to <port-file>.
Logs each request line with the credentials it was sent with, answers
requests without an `Authorization` header with 401, and passes the others
to `<git> http-backend`.
"""

import base64
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

GIT, PROJECT_ROOT, PORT_FILE = sys.argv[1:4]


class Handler(BaseHTTPRequestHandler):
    """Request handler, see the module doc comment."""

    def do_GET(self):
        """Handle a GET request."""
        self.handle_git()

    def do_POST(self):
        """Handle a POST request."""
        self.handle_git()

    def handle_git(self):
        """Check the credentials and run `git http-backend`."""
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length)

        auth = self.headers.get("Authorization")
        user = None
        if auth and auth.startswith("Basic "):
            user = base64.b64decode(auth[6:]).decode()
        print(f"{self.command} {self.path} auth={user or '-'}", flush=True)

        if user is None:
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="test"')
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        path, _, query = self.path.partition("?")
        env = {
            "PATH": os.environ.get("PATH", ""),
            "GIT_PROJECT_ROOT": PROJECT_ROOT,
            "GIT_HTTP_EXPORT_ALL": "1",
            "REQUEST_METHOD": self.command,
            "PATH_INFO": path,
            "QUERY_STRING": query,
            "CONTENT_TYPE": self.headers.get("Content-Type", ""),
            "CONTENT_LENGTH": str(length),
            "HTTP_CONTENT_ENCODING": self.headers.get("Content-Encoding", ""),
            "REMOTE_USER": user.partition(":")[0],
            "GIT_PROTOCOL": self.headers.get("Git-Protocol", ""),
        }
        result = subprocess.run(
            [GIT, "http-backend"], input=body, env=env, capture_output=True, check=False
        )
        sys.stderr.buffer.write(result.stderr)

        head, _, content = result.stdout.partition(b"\r\n\r\n")
        status = 200
        headers = []
        for line in head.decode().split("\r\n"):
            name, _, value = line.partition(":")
            if name.lower() == "status":
                status = int(value.split()[0])
            elif name:
                headers.append((name, value.strip()))

        self.send_response(status)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def log_message(self, format, *args):
        """Skip the default access log, handle_git logs the requests."""


server = HTTPServer(("127.0.0.1", 0), Handler)
with open(PORT_FILE, "w") as file:
    file.write(str(server.server_port))
server.serve_forever()
