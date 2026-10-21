#!/usr/bin/env bash
# Deploy lewat Git dari Pop!_OS:  ./deploy/deploy_git.sh
# Syarat: perubahan sudah di-commit. Skrip ini push ke GitHub, lalu VM pull, sync dependensi, restart.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Ada perubahan yang belum di-commit. Commit dulu, lalu jalankan lagi." >&2
  git status --short >&2
  exit 1
fi

echo "==> Push ke GitHub"
git push origin main

echo "==> VM: pull, sync dependensi (uv.lock), restart"
ssh -t marine 'set -e; cd ~/marine-hello \
  && git pull --ff-only \
  && echo "    versi di VM: $(git log -1 --format="%h %s")" \
  && ~/.local/bin/uv sync --frozen \
  && if ! cmp -s deploy/marine-hello.service /etc/systemd/system/marine-hello.service; then \
       echo "    file service berubah, memasang ulang"; \
       sudo cp deploy/marine-hello.service /etc/systemd/system/ && sudo systemctl daemon-reload; \
     fi \
  && sudo systemctl restart marine-hello \
  && sleep 2 && curl -s http://127.0.0.1:8000/api/health && echo'
