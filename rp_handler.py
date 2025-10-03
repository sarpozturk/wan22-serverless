import runpod, os, time, json, base64, uuid, requests, glob

COMFY_API = "http://127.0.0.1:8188"
WORKFLOW_PATH = "/workspace/workflow.json"
OUTPUT_DIR = "/workspace/ComfyUI/output"

def _post_prompt(workflow):
    return requests.post(f"{COMFY_API}/prompt", json={"prompt": workflow}).json()

def _get_history(prompt_id):
    return requests.get(f"{COMFY_API}/history/{prompt_id}").json()

def _wait_for_done(prompt_id, timeout=600):
    t0 = time.time()
    while time.time() - t0 < timeout:
        h = _get_history(prompt_id)
        # Tamamlandığında history içinde output paths oluşur
        if prompt_id in h and h[prompt_id].get("outputs"):
            return h[prompt_id]["outputs"]
        time.sleep(1)
    raise TimeoutError("ComfyUI workflow timeout")

def handler(job):
    inp = job["input"]
    prompt_text = inp.get("prompt", "")
    image_b64 = inp.get("image")  # base64 bekliyoruz

    # Girdi görselini diske yaz
    input_path = f"/workspace/input_{uuid.uuid4().hex}.png"
    if image_b64:
        with open(input_path, "wb") as f:
            f.write(base64.b64decode(image_b64))
    else:
        return {"error": "image (base64) is required"}

    # Workflow'u yükle/doldur
    with open(WORKFLOW_PATH, "r") as f:
        wf = json.load(f)

    # Positive prompt node'u ve LoadImage node'unu doldur
    for _, node in wf.items():
        if node.get("class_type") == "PrimitiveStringMultiline" and "Positive" in node.get("_meta", {}).get("title",""):
            node["inputs"]["value"] = prompt_text
        if node.get("class_type") == "LoadImage":
            node["inputs"]["image"] = input_path

    # Çalıştır
    resp = _post_prompt(wf)
    prompt_id = resp.get("prompt_id")
    if not prompt_id:
        return {"error": f"ComfyUI prompt error: {resp}"}

    _wait_for_done(prompt_id, timeout=1800)  # WAN 2.2 i2v uzun sürebilir

    # Son .mp4 dosyasını al
    vids = sorted(glob.glob(os.path.join(OUTPUT_DIR, "**", "*.mp4"), recursive=True), key=os.path.getmtime)
    if not vids:
        return {"error": "No video file produced"}
    video_path = vids[-1]

    with open(video_path, "rb") as f:
        video_b64 = base64.b64encode(f.read()).decode()

    return {
        "video_base64": video_b64,
        "format": "mp4",
        "prompt": prompt_text
    }

runpod.serverless.start({"handler": handler})
