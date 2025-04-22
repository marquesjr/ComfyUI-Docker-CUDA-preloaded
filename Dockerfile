FROM nvidia/cuda:12.8.1-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COMFYUI_DIR=/app/ComfyUI \
    PATH="/venv/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# Copy initialization script
COPY init_scripts/init_models.sh /usr/local/bin/
COPY init_scripts/init_extensions.sh /usr/local/bin/
COPY init_scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_models.sh
RUN chmod +x /usr/local/bin/init_extensions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    ninja-build \
    wget \
    fonts-dejavu-core \
    fonts-liberation \
    fontconfig \
    && fc-cache -f -v \
    && rm -rf /var/lib/apt/lists/*

# make sure venv is writable by user "ubuntu"
RUN mkdir -p ${COMFYUI_DIR} /venv && \
    chown -R 1000:1000 /app /venv

USER ubuntu

# Setup virtual environment
RUN python3.12 -m venv /venv

# Install PyTorch with CUDA 12.1
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    xformers \
    --index-url https://download.pytorch.org/whl/cu121

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI ${COMFYUI_DIR}
WORKDIR ${COMFYUI_DIR}

# git checkout to last known stable tag
RUN git fetch --tags && git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

# Install requirements
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir \
    pyyaml \
    opencv-python-headless \
    scikit-image \
    imageio \
    pillow \
    hf-transfer huggingface-hub \
    insightface \
    facexlib \
    git+https://github.com/rodjjo/filterpy.git \
    onnxruntime onnxruntime-gpu \
    opencv-python opencv-python-headless

# Create directory structure (will be overridden by volumes)
RUN mkdir -p models input output custom_nodes

# Copy models and extensions configuration lists:
COPY extensions.conf /app/extensions.conf
COPY models.conf /app/models.conf

# Persistent storage configuration
VOLUME ["/app/ComfyUI/models", "/app/ComfyUI/output", "/app/ComfyUI/input", "/app/ComfyUI/custom_nodes"]
VOLUME ["/venv"]

EXPOSE 8188

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["python3", "main.py", "--listen", "--port", "8188", "--enable-cors-header", "*"]
