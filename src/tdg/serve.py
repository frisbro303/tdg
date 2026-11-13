"""tdg serve: build, serve on localhost, and rebuild (and reload the browser) when sources change."""
import functools
import http.server
import shlex
import subprocess
import threading
import time
from pathlib import Path

from tdg.build import BuildError, build
from tdg.config import ConfigError, load

SKIP = {".git", "__pycache__", "node_modules", ".venv", ".DS_Store"}


class _Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def snapshot(root, ignore):
    """Every file under root that matters to the site, with its modification time."""
    files = {}
    for path in root.rglob("*"):
        parts = path.relative_to(root).parts
        if path.is_file() and not (SKIP | ignore).intersection(parts):
            files[path] = path.stat().st_mtime
    return files


def rebuild(root, report):
    try:
        config = load(root)
        result = build(config, dev=True)
        for warning in result.warnings:
            print("warning:", warning)
        print(f"Built {len(result.entries)} page(s) in {result.seconds:.1f}s")
        return config
    except (ConfigError, BuildError) as e:
        print("error:", e)
        return None


def serve(root, port=None):
    root = Path(root).resolve()
    config = load(root)
    port = port or config.serve.get("port", 8000)
    out = root / config.out
    rebuild(root, print)
    handler = functools.partial(_Quiet, directory=str(out))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"Serving on http://localhost:{port}/ (ctrl+c to stop)")
    ignore = {config.out, *config.serve.get("ignore", [])}
    before = snapshot(root, ignore)
    while True:
        time.sleep(0.4)
        now = snapshot(root, ignore)
        changed = sorted(p for p in now.keys() | before.keys() if now.get(p) != before.get(p))
        if not changed:
            continue
        print("Changed:", ", ".join(str(p.relative_to(root)) for p in changed))
        command = config.serve.get("on_change")
        if command:  # say, re-render figures; {files} is the changed files
            files = " ".join(shlex.quote(str(p.relative_to(root))) for p in changed)
            subprocess.run(command.replace("{files}", files), shell=True, cwd=root)
        config = rebuild(root, print) or config
        before = snapshot(root, ignore)
