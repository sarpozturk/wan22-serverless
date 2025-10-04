#!/bin/bash
set -e
source /venv/bin/activate

cd /workspace/ComfyUI
echo "Starting ComfyUI..."
python -u main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &

# Health check – wait until ComfyUI backend is ready
echo "Waiting for ComfyUI to start..."
until curl -s http://127.0.0.1:8188/system_stats | grep -q '"cpu"'; do
  echo "Still waiting for ComfyUI..."
  sleep 1
done

echo "✅ ComfyUI is ready! Starting handler..."
cd /workspace
python -u rp_handler.py
