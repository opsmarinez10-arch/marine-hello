#!/usr/bin/env bash
# Deploy lewat Git dari Pop!_OS:  ./deploy/deploy_git.sh
# Syarat: perubahan sudah di-commit. Skrip ini push ke GitHub, lalu VM pull dan restart.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Ada perubahan yang belum di-commit. Commit dulu, lalu jalankan lagi." >&2
  git status --short >&2
  exit 1
fi

echo "==> Push ke GitHub"
git push origin main

echo "==> VM: pull, update dependensi, restart"
ssh -t marine 'cd ~/marine-hello \
  && git pull --ff-only \
  && echo "    versi di VM: $(git log -1 --format="%h %s")" \
  && .venv/bin/pip install -q -r requirements.txt \
  && sudo systemctl restart marine-hello \
  && sleep 2 && curl -s http://127.0.0.1:8000/api/health && echo'
