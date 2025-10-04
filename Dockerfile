# ============================================================
#  WAN 2.2 Image-to-Video Serverless Dockerfile (ComfyUI base)
# ============================================================

FROM nvidia/cuda:12.4.1-cudnn8-devel-ubuntu22.04

# ---- Environment ----
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---- Python & Tools ----
RUN apt-get update && \
    apt-get install -y python3.10 python3.10-venv python3.10-dev git curl ffmpeg && \
    ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    rm -rf /var/lib/apt/lists/*

# ---- Virtualenv ----
RUN python3.10 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install --upgrade pip

# ---- Torch + Deps ----
RUN pip install torch==2.4.1+cu124 torchvision==0.19.1+cu124 torchaudio==2.4.1 --extra-index-url https://download.pytorch.org/whl/cu124
RUN pip install runpod requests accelerate diffusers transformers safetensors moviepy websocket-client ftfy sageattention

# ---- ComfyUI ----
WORKDIR /workspace
RUN rm -rf /workspace/ComfyUI && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
WORKDIR /workspace/ComfyUI
RUN pip install -r requirements.txt

# ---- Custom Nodes ----
WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
# WAN Video Wrapper Node (gerekli!)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt || true

# ---- Back to workspace ----
WORKDIR /workspace

# ---- Copy app files ----
COPY workflow.json /workspace/workflow.json
COPY rp_handler.py /workspace/rp_handler.py
COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

EXPOSE 8188
ENTRYPOINT ["/bin/bash", "/workspace/start.sh"]