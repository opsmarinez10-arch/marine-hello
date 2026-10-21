#!/usr/bin/env bash
# Deploy ulang dari Pop!_OS setelah mengubah kode:  ./deploy/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Kirim kode ke VM (rsync)"
rsync -av --delete \
  --exclude .venv --exclude __pycache__ --exclude .git --exclude .env \
  ./ marine:~/marine-hello/

echo "==> Update dependensi dan restart service"
ssh -t marine 'cd ~/marine-hello && .venv/bin/pip install -q -r requirements.txt && sudo systemctl restart marine-hello && sleep 2 && curl -s http://127.0.0.1:8000/api/health && echo'
