#!/usr/bin/env bash
# Setup / migrasi di VM. Aman dijalankan ulang.
# Dari Pop!_OS:  ssh -t marine 'bash ~/marine-hello/deploy/setup_vm.sh'
set -euo pipefail
cd "$HOME/marine-hello"

echo "==> Pasang uv (kalau belum ada)"
if [ ! -x "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
UV="$HOME/.local/bin/uv"
"$UV" --version

echo "==> Siapkan folder data dan config di luar repo"
mkdir -p "$HOME/marine-data/marine-hello" "$HOME/.config"
touch "$HOME/.config/marine-hello.env"
chmod 600 "$HOME/.config/marine-hello.env"

echo "==> Buat ulang .venv dengan Python dari .python-version (sesuai uv.lock)"
sudo systemctl stop marine-hello 2>/dev/null || true
rm -rf .venv
"$UV" python install
"$UV" sync --frozen
.venv/bin/python --version

echo "==> Pasang ulang service dan nyalakan"
sudo cp deploy/marine-hello.service /etc/systemd/system/marine-hello.service
sudo systemctl daemon-reload
sudo systemctl enable --now marine-hello
sudo systemctl restart marine-hello

sleep 2
systemctl --no-pager status marine-hello | head -n 5
echo
curl -s http://127.0.0.1:8000/api/health && echo
echo "==> Selesai."
