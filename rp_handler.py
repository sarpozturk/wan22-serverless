import runpod
import requests
import base64
import time
import os
import json

COMFY_API = "http://127.0.0.1:8188"

# ComfyUI'de yüklü workflow'u çağırır
def run_workflow(image_b64: str):
    # Görseli input klasörüne kaydet
    os.makedirs("/workspace/input", exist_ok=True)
    input_path = "/workspace/input/input.png"
    with open(input_path, "wb") as f:
        f.write(base64.b64decode(image_b64))

    # Workflow'u oku
    with open("/workspace/workflow.json", "r") as f:
        workflow = json.load(f)

    # İlk node'un input'una dosya path'i ekle
    for node_id, node in workflow["nodes"].items():
        if "input_image" in node.get("inputs", {}):
            node["inputs"]["input_image"] = input_path

    # Gönder
    res = requests.post(f"{COMFY_API}/prompt", json={"prompt": workflow})
    prompt_id = res.json().get("prompt_id")

    # İş bitene kadar bekle
    while True:
        time.sleep(2)
        history = requests.get(f"{COMFY_API}/history/{prompt_id}").json()
        if prompt_id in history and "outputs" in history[prompt_id]:
            outputs = history[prompt_id]["outputs"]
            for node in outputs.values():
                if "output" in node:
                    file_name = node["output"]["images"][0]["filename"]
                    file_path = f"/workspace/ComfyUI/output/{file_name}"
                    if os.path.exists(file_path):
                        with open(file_path, "rb") as f:
                            return base64.b64encode(f.read()).decode()
        print("⏳ Waiting for result...")

# RunPod handler
def handler(event):
    image_b64 = event["input"].get("image")
    if not image_b64:
        return {"error": "No input image provided."}

    try:
        output_b64 = run_workflow(image_b64)
        return {"video_base64": output_b64}
    except Exception as e:
        return {"error": str(e)}

runpod.serverless.start({"handler": handler})
