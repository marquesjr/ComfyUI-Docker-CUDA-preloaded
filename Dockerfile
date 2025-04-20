FROM nvidia/cuda:12.6.0-devel-ubuntu22.04

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COMFYUI_DIR=/app/ComfyUI \
    PATH="/venv/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# Copy initialization script
COPY init_models.sh /usr/local/bin/
COPY init_extensions.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_models.sh
RUN chmod +x /usr/local/bin/init_extensions.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create user and configure directories
RUN groupadd -g $GID comfyuser && \
    useradd -u $UID -g $GID -m -s /bin/bash comfyuser && \
    mkdir -p ${COMFYUI_DIR} /venv && \
    chown -R $UID:$GID /app /venv

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
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

USER $UID:$GID
ENV UID=${UID} \
    GID=${GID}

# Setup virtual environment
RUN python3.11 -m venv /venv

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

# Persistent storage configuration
VOLUME ["/app/ComfyUI/models", "/app/ComfyUI/output", "/app/ComfyUI/input", "/app/ComfyUI/custom_nodes"]
VOLUME ["/venv"]

EXPOSE 8188

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["python3", "main.py", "--listen", "--port", "8188", "--enable-cors-header", "*"]
