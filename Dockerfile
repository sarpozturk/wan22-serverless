# Dockerfile (SLIM)
FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04

# ---- Python & tools ----
RUN apt-get update && \
    apt-get install -y python3.10 python3.10-venv python3.10-dev git curl ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# ---- venv ----
RUN python3.10 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install --upgrade pip

# ---- Torch + deps ----
# Not: TorchCompile / SageAttention gibi hızlandırmalar için daha yeni torch/triton da seçilebilir,
# ilk etapta güvenli bir sürümle gidelim.
RUN pip install torch==2.2.0+cu121 torchvision==0.17.0+cu121 --extra-index-url https://download.pytorch.org/whl/cu121
RUN pip install runpod requests accelerate diffusers transformers safetensors moviepy

# ---- ComfyUI ----
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /workspace/ComfyUI
RUN pip install -r requirements.txt

# ---- Custom nodes (workflow için gerekli) ----
# VHS (VideoCombine) → gerekli. Kaynak: Kosinkadink/ComfyUI-VideoHelperSuite  [oai_citation:2‡GitHub](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite?utm_source=chatgpt.com)
WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
# KJNodes (PatchSageAttentionKJ, schedulers, sampler vb.) → gerekli. (TorchCompileModelWanVideoV2 KJNodes içinde)  [oai_citation:3‡comfy.icu](https://comfy.icu/node/TorchCompileModelWanVideoV2?utm_source=chatgpt.com)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git

# (Wan özel node’u gerekmiyor; bu workflow WAN 2.2’yi UNETLoader ile safetensors’tan yüklüyor  [oai_citation:4‡wan22_nolora.json](sediment://file_00000000818c620a8a35c906597e70e8).
# WanFirstLastFrameToVideo kullanan varyantta ek node gerekirdi; burada yok. )

# ---- Çalışma alanı ----
WORKDIR /workspace
COPY ./workflow.json /workspace/workflow.json
COPY ./rp_handler.py /workspace/rp_handler.py
COPY ./start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

EXPOSE 8188
CMD ["/workspace/start.sh"]
