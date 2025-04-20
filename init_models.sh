#!/bin/bash

# Create directory structure if missing
mkdir -p /app/ComfyUI/models/checkpoints \
  /app/ComfyUI/models/text_encoders \
  /app/ComfyUI/models/diffusion_models \
  /app/ComfyUI/models/clip_vision \
  /app/ComfyUI/models/loras \
  /app/ComfyUI/models/controlnet \
  /app/ComfyUI/models/upscale_models \
  /app/ComfyUI/models/vae

# Download base models if they don't exist
BASE_MODELS=(
  "https://huggingface.co/lllyasviel/flux1_dev/resolve/main/flux1-dev-fp8.safetensors"
  "https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev.safetensors"
  "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
  "https://huggingface.co/comfyanonymous/hunyuan_dit_comfyui/resolve/main/hunyuan_dit_1.2.safetensors"
  "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors"
  "https://huggingface.co/fal/AuraFlow-v0.2/resolve/main/aura_flow_0.2.safetensors"
  "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
)

UPSCALE_MODELS=(
  "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/a86fc6182b4650b4459cb1ddcb0a0d1ec86bf3b0/RealESRGAN_x2.pth"
  "https://huggingface.co/skbhadra/ClearRealityV1/resolve/bc01e27b38eec683dc6e3161dd56069c78e015ac/4x-ClearRealityV1.pth"
  "https://huggingface.co/ac-pill/upscale_models/resolve/main/RealESRGAN_x4plus_anime_6B.pth"
)

TEXT_ENCODERS=(
  "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
  "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors"
  "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/text_encoders/llava_llama3_fp16.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/text_encoders/llava_llama3_fp8_scaled.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/text_encoders/clip_l_hidream.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/text_encoders/clip_g_hidream.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/text_encoders/t5xxl_fp8_e4m3fn_scaled.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/text_encoders/llama_3.1_8b_instruct_fp8_scaled.safetensors"
)

WEIGHTS=(
  "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors"
  "https://huggingface.co/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/diffusion_models/hidream_i1_dev_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/diffusion_models/hidream_i1_full_fp16.safetensors"
)

CLIP_VISION=(
  "https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/clip_vision/llava_llama3_vision.safetensors"
  "https://huggingface.co/comfyanonymous/clip_vision_g/resolve/main/clip_vision_g.safetensors"
)

CLIP=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/2b03fd4a8280bda491f5e54e96ad38fd8ab7336b/ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF.safetensors"
)

VAE=(
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/vae/ae.safetensors"
)

# ---------------------------------------------
# download_list: fetch URLs, optional rename, and continue on error
# ---------------------------------------------
download_list() {
  # Usage: download_list <array_name> <subdir>
  local arr_name="$1[@]"
  local target_dir="/app/ComfyUI/models/$2"

  for entry in "${!arr_name}"; do
    # split URL and optional new filename (after '|')
    local url="${entry%%|*}"
    local name_part="${entry#*|}"
    local filename
    if [[ "$entry" == *"|"* ]]; then
      filename="$name_part"
    else
      filename="$(basename "$url")"
    fi

    mkdir -p "$target_dir"
    if [ ! -f "$target_dir/$filename" ]; then
      echo "Downloading $filename..."
      if ! wget -q --show-progress -O "$target_dir/$filename" "$url"; then
        echo "Warning: failed to download $url"
        continue
      fi
    fi
  done
}

# ---------------------------------------------
# Execute downloads for each model type
# ---------------------------------------------
download_list BASE_MODELS checkpoints
download_list TEXT_ENCODERS text_encoders
download_list WEIGHTS diffusion_models
download_list CLIP_VISION clip_vision
download_list CLIP clip
download_list VAE vae
download_list UPSCALE_MODELS upscale_models
#download_list LORAS             loras
#download_list CONTROLNET        controlnet

# Set proper permissions
groupid=$(id -g)
userid=$(id -u)
chown -R $UID:$GID /app/ComfyUI/models
