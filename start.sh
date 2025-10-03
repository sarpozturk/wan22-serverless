#!/bin/bash
set -e
source /venv/bin/activate

# ComfyUI'yi headless başlat
cd /workspace/ComfyUI
# --listen ve --port ile API aç, --disable-auto-launch ile tarayıcı yok
python -u main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &

# API hazır olana kadar bekle
until curl -s http://127.0.0.1:8188/system_stats > /dev/null; do
  echo "Waiting for ComfyUI..."
  sleep 1
done

# handler
cd /workspace
python -u rp_handler.py
