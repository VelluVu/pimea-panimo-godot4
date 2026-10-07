"""Smoke test for the web build in a real (headless) Chrome.

Serves build/web, opens it in headless Chrome through the DevTools protocol, waits in real
time, clicks or presses keys if asked, and saves screenshots plus every console message.
Needs only the Python standard library and an installed Chrome.

    python dev/tools/web/web_smoke.py [--wait 40] [--steps "click 640 400; wait 3; shot menu"]
        [--out DIR] [--chrome PATH] [--keep-profile] [--url URL]

--url tests a published copy (GitHub Pages, itch.io) instead of serving build/web.

Steps run after the first wait, separated by ';':
    click X Y      left click at page pixels (the page is 1280x720, the game 640x360 x2)
    key NAME       press and release a key (Escape, Enter, Space, a letter, F1...)
    wait SECONDS   sleep
    shot NAME      save a screenshot as NAME.png
    js EXPRESSION  evaluate JavaScript in the page and print the result
--init-script FILE runs a JavaScript file in the page before the game loads (for probes).
A screenshot "loaded.png" is always taken after the first wait. Exits 1 if the page logged
an uncaught exception or a console error.
"""

import argparse
import base64
import functools
import http.server
import json
import os
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
BUILD_DIR = os.path.join(ROOT, "build", "web")
DEFAULT_OUT = os.path.join(ROOT, "dev", "tools", "web", "out")
DEFAULT_CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
WINDOW = (1280, 720)
SERVE_PORT = 8062
DEBUG_PORT = 9233

KEYS = {
	"Escape": (27, "Escape"), "Enter": (13, "Enter"), "Space": (32, " "),
	"Tab": (9, "Tab"), "Backspace": (8, "Backspace"),
}


class WebSocket:
	"""Just enough of RFC 6455 for one DevTools connection: masked client text frames,
	unfragmented server frames of any length."""

	def __init__(self, url):
		host_port, path = url[len("ws://"):].split("/", 1)
		host, port = host_port.split(":")
		self.sock = socket.create_connection((host, int(port)))
		key = base64.b64encode(os.urandom(16)).decode()
		self.sock.sendall((
			f"GET /{path} HTTP/1.1\r\nHost: {host_port}\r\nUpgrade: websocket\r\n"
			f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
		).encode())
		response = b""
		while b"\r\n\r\n" not in response:
			response += self.sock.recv(1)
		if b" 101 " not in response.split(b"\r\n")[0]:
			raise RuntimeError("websocket handshake failed: " + response.decode(errors="replace"))

	def send(self, text):
		data = text.encode()
		header = bytes([0x81])
		if len(data) < 126:
			header += bytes([0x80 | len(data)])
		elif len(data) < 65536:
			header += bytes([0x80 | 126]) + struct.pack(">H", len(data))
		else:
			header += bytes([0x80 | 127]) + struct.pack(">Q", len(data))
		mask = os.urandom(4)
		self.sock.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

	def _read(self, n):
		buf = b""
		while len(buf) < n:
			chunk = self.sock.recv(n - len(buf))
			if not chunk:
				raise ConnectionError("websocket closed")
			buf += chunk
		return buf

	def recv(self, timeout):
		self.sock.settimeout(timeout)
		try:
			first, second = self._read(2)
		except socket.timeout:
			return None
		self.sock.settimeout(None)
		length = second & 0x7F
		if length == 126:
			length = struct.unpack(">H", self._read(2))[0]
		elif length == 127:
			length = struct.unpack(">Q", self._read(8))[0]
		payload = self._read(length)
		return payload.decode(errors="replace") if first & 0x0F == 1 else ""


class DevTools:
	def __init__(self, ws):
		self.ws = ws
		self.next_id = 0
		self.console = []

	def call(self, method, params=None, timeout=30.0):
		self.next_id += 1
		my_id = self.next_id
		self.ws.send(json.dumps({"id": my_id, "method": method, "params": params or {}}))
		deadline = time.time() + timeout
		while time.time() < deadline:
			message = self._next(deadline - time.time())
			if message is not None and message.get("id") == my_id:
				if "error" in message:
					raise RuntimeError(f"{method}: {message['error']}")
				return message.get("result", {})
		raise TimeoutError(method)

	def pump(self, seconds):
		deadline = time.time() + seconds
		while time.time() < deadline:
			self._next(deadline - time.time())

	def _next(self, timeout):
		text = self.ws.recv(max(timeout, 0.01))
		if not text:
			return None
		message = json.loads(text)
		method = message.get("method")
		if method == "Runtime.consoleAPICalled":
			args = " ".join(str(a.get("value", a.get("description", ""))) for a in message["params"]["args"])
			self.console.append((message["params"]["type"], args))
		elif method == "Runtime.exceptionThrown":
			details = message["params"]["exceptionDetails"]
			self.console.append(("exception", details.get("exception", {}).get("description", details.get("text", ""))))
		return message


class QuietHandler(http.server.SimpleHTTPRequestHandler):
	"""Always the full file, never cached: a 304 left Godot's loader with a network error."""

	def send_head(self):
		if "If-Modified-Since" in self.headers:
			del self.headers["If-Modified-Since"]
		return super().send_head()

	def end_headers(self):
		self.send_header("Cache-Control", "no-store")
		super().end_headers()

	def log_message(self, *args):
		pass


def serve(directory):
	handler = functools.partial(QuietHandler, directory=directory)
	server = http.server.ThreadingHTTPServer(("127.0.0.1", SERVE_PORT), handler)
	threading.Thread(target=server.serve_forever, daemon=True).start()
	return server


def page_websocket_url():
	for _ in range(50):
		try:
			with urllib.request.urlopen(f"http://127.0.0.1:{DEBUG_PORT}/json/list") as response:
				for target in json.load(response):
					if target.get("type") == "page":
						return target["webSocketDebuggerUrl"]
		except OSError:
			pass
		time.sleep(0.2)
	raise RuntimeError("Chrome did not open a debugging port")


def screenshot(tools, out_dir, name):
	data = tools.call("Page.captureScreenshot", {"format": "png"})["data"]
	path = os.path.join(out_dir, name + ".png")
	with open(path, "wb") as f:
		f.write(base64.b64decode(data))
	print("screenshot", path)


def click(tools, x, y):
	for kind in ("mousePressed", "mouseReleased"):
		tools.call("Input.dispatchMouseEvent", {"type": kind, "x": x, "y": y, "button": "left", "clickCount": 1})


def press(tools, name):
	code, key = KEYS.get(name, (ord(name.upper()) if len(name) == 1 else 0, name))
	for kind in ("keyDown", "keyUp"):
		tools.call("Input.dispatchKeyEvent", {"type": kind, "key": key, "windowsVirtualKeyCode": code, "code": name})


def run_steps(tools, steps, out_dir):
	for step in filter(None, (s.strip() for s in steps.split(";"))):
		verb, *args = step.split()
		if verb == "click":
			click(tools, float(args[0]), float(args[1]))
			tools.pump(0.3)
		elif verb == "key":
			press(tools, args[0])
			tools.pump(0.3)
		elif verb == "wait":
			tools.pump(float(args[0]))
		elif verb == "shot":
			screenshot(tools, out_dir, args[0])
		elif verb == "js":
			result = tools.call("Runtime.evaluate", {"expression": step[3:].strip(), "returnByValue": True})
			print("js", result.get("result", {}).get("value"))
		else:
			raise ValueError("unknown step: " + step)


def main():
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument("--wait", type=float, default=40.0, help="seconds to let the game load")
	parser.add_argument("--steps", default="", help="steps after loading, see above")
	parser.add_argument("--out", default=DEFAULT_OUT)
	parser.add_argument("--chrome", default=os.environ.get("CHROME", DEFAULT_CHROME))
	parser.add_argument("--keep-profile", action="store_true", help="reuse the browser profile, so saves survive between runs")
	parser.add_argument("--url", default="", help="a published copy to test instead of build/web")
	parser.add_argument("--init-script", default="", help="JavaScript file to run in the page before it loads")
	args = parser.parse_args()

	if not args.url and not os.path.isfile(os.path.join(BUILD_DIR, "index.html")):
		sys.exit("No build/web/index.html: export the Web Demo preset first.")
	os.makedirs(args.out, exist_ok=True)
	profile = os.path.join(args.out, "profile") if args.keep_profile else tempfile.mkdtemp(prefix="web_smoke_")

	server = None if args.url else serve(BUILD_DIR)
	url = args.url or f"http://127.0.0.1:{SERVE_PORT}/index.html"
	chrome = subprocess.Popen([
		args.chrome, "--headless=new", f"--remote-debugging-port={DEBUG_PORT}", f"--user-data-dir={profile}",
		f"--window-size={WINDOW[0]},{WINDOW[1]}", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
		"--autoplay-policy=no-user-gesture-required",
		# Muted, or the game plays through the developer's speakers; Web Audio still runs.
		"--mute-audio", "about:blank",
	], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
	try:
		tools = DevTools(WebSocket(page_websocket_url()))
		tools.call("Runtime.enable")
		tools.call("Page.enable")
		if args.init_script:
			with open(args.init_script, encoding="utf-8") as f:
				tools.call("Page.addScriptToEvaluateOnNewDocument", {"source": f.read()})
		tools.call("Page.navigate", {"url": url})
		tools.pump(args.wait)
		screenshot(tools, args.out, "loaded")
		run_steps(tools, args.steps, args.out)
	finally:
		# Chrome can hand over to a new main process, and its helpers outlive it: stop every
		# Chrome using this run's profile, or they keep playing the game in the background.
		if os.name == "nt":
			subprocess.run(["taskkill", "/PID", str(chrome.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
			subprocess.run(["powershell", "-NoProfile", "-Command",
				"Get-CimInstance Win32_Process -Filter \"Name = 'chrome.exe'\" | Where-Object { $_.CommandLine.Contains('"
				+ os.path.abspath(profile).replace("'", "''") + "') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"],
				stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
		else:
			chrome.terminate()
		chrome.wait(10)
		if server is not None:
			server.shutdown()
		if not args.keep_profile:
			shutil.rmtree(profile, ignore_errors=True)

	failures = [(kind, text) for kind, text in tools.console if kind in ("exception", "error")]
	for kind, text in tools.console:
		print(f"[{kind}] {text[:300]}")
	print(f"{len(tools.console)} console messages, {len(failures)} errors")
	sys.exit(1 if failures else 0)


if __name__ == "__main__":
	main()
