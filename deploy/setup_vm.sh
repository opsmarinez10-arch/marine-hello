#!/usr/bin/env bash
# Setup SEKALI di VM. Jalankan dari dalam VM:  bash ~/marine-hello/deploy/setup_vm.sh
set -euo pipefail
cd "$HOME/marine-hello"

echo "==> Pasang python3-venv (sekali saja)"
sudo apt-get install -y python3-venv

echo "==> Buat virtualenv dan pasang dependensi"
python3 -m venv .venv
.venv/bin/pip install --upgrade pip -q
.venv/bin/pip install -r requirements.txt -q

echo "==> Pasang dan nyalakan service systemd"
sudo cp deploy/marine-hello.service /etc/systemd/system/marine-hello.service
sudo systemctl daemon-reload
sudo systemctl enable --now marine-hello

sleep 2
systemctl --no-pager status marine-hello | head -n 5
echo
curl -s http://127.0.0.1:8000/api/health && echo
echo "==> Selesai. Buka dari Pop!_OS: http://100.123.68.53:8000"
