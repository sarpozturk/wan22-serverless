import runpod
import requests
import base64
import json
import os
import time

COMFYUI_URL = "http://127.0.0.1:8188"


def wait_for_comfyui():
    """Wait until ComfyUI backend is reachable."""
    while True:
        try:
            r = requests.get(f"{COMFYUI_URL}/system_stats")
            if r.status_code == 200:
                print("✅ ComfyUI backend is ready.")
                break
        except Exception:
            pass
        print("⏳ Waiting for ComfyUI backend...")
        time.sleep(2)


def get_history(prompt_id):
    """Poll ComfyUI until workflow result is ready."""
    while True:
        try:
            res = requests.get(f"{COMFYUI_URL}/history/{prompt_id}")
            if res.status_code == 200:
                data = res.json()
                if data.get(prompt_id):
                    print("🟢 Workflow complete.")
                    return data[prompt_id]
        except Exception as e:
            print("⏳ Waiting for result...", e)
        time.sleep(2)


def handler(event):
    """Handle incoming RunPod request."""
    input_data = event.get("input", {})
    prompt = input_data.get("prompt", "default")
    image_b64 = input_data.get("image")

    # ❌ Prompt zorunlu
    if not prompt:
        return {"error": "Missing 'prompt' in input."}

    # workflow.json yükle
    with open("/workflow.json", "r") as f:
        workflow = json.load(f)

    # workflow içindeki text input'u değiştir
    for node_id, node in workflow.items():
        if node.get("class_type") in ["CLIPTextEncode", "Text"]:
            if "inputs" in node and "text" in node["inputs"]:
                node["inputs"]["text"] = prompt

    # ComfyUI'ye gönder
    print(f"🚀 Sending prompt to ComfyUI: {prompt}")
    res = requests.post(f"{COMFYUI_URL}/prompt", json={"prompt": workflow})
    prompt_id = res.json().get("prompt_id")

    if not prompt_id:
        return {"error": "Failed to get prompt_id", "response": res.text}

    # Sonucu bekle
    result = get_history(prompt_id)

    # İlk çıktıyı al
    outputs = result.get("outputs", {})
    images = []
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for img in node_output["images"]:
                img_path = os.path.join("/workspace/ComfyUI/output", img["filename"])
                if os.path.exists(img_path):
                    with open(img_path, "rb") as f:
                        images.append(base64.b64encode(f.read()).decode("utf-8"))

    return {
        "status": "success",
        "prompt": prompt,
        "num_images": len(images),
        "images_base64": images[:1]  # sadece 1 tanesini döndür
    }


# ✅ Serverless ortamda otomatik başlat
print("--- Starting Serverless Worker | Version 1.7.13 ---")
wait_for_comfyui()
runpod.serverless.start({"handler": handler})
