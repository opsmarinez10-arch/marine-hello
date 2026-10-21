"""Marine Agent — hello world untuk menguji alur deploy ke VM marine-agent."""

import json
import os
import platform
import shutil
import socket
import threading
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

APP_VERSION = "0.2.0"
TZ = ZoneInfo("Asia/Makassar")

# Data hidup di LUAR folder repo, supaya deploy (git reset/pull) tidak pernah menyentuhnya.
# Di VM diisi lewat EnvironmentFile service; default untuk dev lokal: ./.data (di-ignore Git).
DATA_DIR = Path(os.environ.get("MARINE_DATA_DIR", Path(__file__).resolve().parent.parent / ".data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
_VISITS_FILE = DATA_DIR / "visits.json"
_lock = threading.Lock()

app = FastAPI(title="Marine Agent", version=APP_VERSION)


def _count_visit() -> int:
    """Tambah dan simpan jumlah kunjungan. Bukti bahwa data bertahan melewati deploy."""
    with _lock:
        try:
            n = json.loads(_VISITS_FILE.read_text())["visits"]
        except (OSError, ValueError, KeyError):
            n = 0
        n += 1
        tmp = _VISITS_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps({"visits": n}))
        tmp.replace(_VISITS_FILE)  # tulis atomik: file tidak rusak kalau proses mati di tengah
        return n


def _disk_free() -> str:
    usage = shutil.disk_usage(DATA_DIR)
    return f"{usage.free / 1e9:.1f} GB bebas dari {usage.total / 1e9:.1f} GB"


def _uptime() -> str:
    """Uptime VM dari /proc/uptime (Linux saja)."""
    try:
        with open("/proc/uptime") as f:
            seconds = int(float(f.read().split()[0]))
    except OSError:
        return "tidak diketahui"
    days, rem = divmod(seconds, 86400)
    hours, rem = divmod(rem, 3600)
    minutes = rem // 60
    return f"{days} hari {hours} jam {minutes} menit"


def _status() -> dict:
    return {
        "app": "Marine Agent",
        "version": APP_VERSION,
        "host": socket.gethostname(),
        "python": platform.python_version(),
        "uptime": _uptime(),
        "time_wita": datetime.now(TZ).strftime("%Y-%m-%d %H:%M:%S"),
        "data_dir": str(DATA_DIR),
        "disk": _disk_free(),
    }


@app.get("/api/health")
def health() -> dict:
    """Endpoint untuk cek cepat dari terminal: curl http://marine-agent:8000/api/health"""
    return {"status": "ok", **_status()}


@app.get("/", response_class=HTMLResponse)
def home() -> str:
    s = _status()
    visits = _count_visit()
    rows = "".join(
        f"<tr><th>{k}</th><td>{v}</td></tr>"
        for k, v in [
            ("Host", s["host"]),
            ("Versi app", s["version"]),
            ("Python", s["python"]),
            ("Uptime VM", s["uptime"]),
            ("Waktu (WITA)", s["time_wita"]),
            ("Folder data", s["data_dir"]),
            ("Disk", s["disk"]),
            ("Kunjungan", visits),
        ]
    )
    return f"""<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Marine Agent</title>
<style>
  :root {{ --bg:#f4f1ea; --ink:#1d2a33; --muted:#5b6b75; --line:#d9d2c3; --accent:#0f5c6e; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg:#121a1f; --ink:#e6e2d8; --muted:#97a4ab; --line:#2a363d; --accent:#5fb3c4; }}
  }}
  body {{ margin:0; background:var(--bg); color:var(--ink);
         font:16px/1.5 Georgia, "Iowan Old Style", serif; }}
  main {{ max-width:560px; margin:10vh auto; padding:0 16px; }}
  h1 {{ font-weight:600; letter-spacing:-0.01em; margin:0 0 4px; }}
  p {{ color:var(--muted); margin:0 0 28px; }}
  table {{ width:100%; border-collapse:collapse; font-family:ui-monospace, Menlo, monospace; font-size:14px; }}
  th, td {{ text-align:left; padding:10px 0; border-top:1px solid var(--line); }}
  th {{ color:var(--muted); font-weight:400; width:40%; }}
  .dot {{ display:inline-block; width:8px; height:8px; border-radius:50%;
          background:var(--accent); margin-right:8px; vertical-align:middle; }}
</style>
</head>
<body>
<main>
  <h1><span class="dot"></span>Marine Agent</h1>
  <p>Server berjalan. Halaman ini dirender langsung dari VM kantor.</p>
  <table>{rows}</table>
</main>
</body>
</html>"""
