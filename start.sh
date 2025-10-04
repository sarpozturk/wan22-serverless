#!/bin/bash
set -e
source /venv/bin/activate

cd /workspace/ComfyUI

# Headless ComfyUI başlat
echo "🚀 Starting ComfyUI..."
python -u main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &

# Health check (ComfyUI hazır olana kadar bekle)
for i in {1..60}; do
  if curl -fs http://127.0.0.1:8188 > /dev/null; then
    echo "✅ ComfyUI is ready!"
    break
  fi
  echo "Waiting for ComfyUI ($i)..."
  sleep 2
done

# Eğer 2 dakika geçtiyse yine de handler'ı çalıştır
cd /workspace
echo "🧠 Starting RunPod handler..."
python -u rp_handler.py
