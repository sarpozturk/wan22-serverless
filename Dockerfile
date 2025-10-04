# ---- Base CUDA Image ----
FROM nvidia/cuda:12.2.0-cudnn8-devel-ubuntu22.04

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

# ---- Torch & Base Deps ----
RUN pip install torch==2.4.1+cu124 torchvision==0.19.1+cu124 --extra-index-url https://download.pytorch.org/whl/cu124
RUN pip install runpod requests accelerate diffusers transformers safetensors moviepy websocket-client opencv-python-headless "numpy<2"

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
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# ---- Back to workspace ----
WORKDIR /workspace

# ---- Copy our files ----
COPY ./workflow.json /workflow.json
COPY ./rp_handler.py /rp_handler.py
COPY ./start.sh /start.sh

RUN chmod +x /start.sh

# ---- Expose API ----
EXPOSE 8188

# ---- Start ----
ENTRYPOINT ["/bin/bash", "/start.sh"]
