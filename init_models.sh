#!/bin/bash
set -euo pipefail

# Directories
MODELS_DIR="/app/ComfyUI/models"
mkdir -p "$MODELS_DIR"

# Create directory structure if missing
mkdir -p "$MODELS_DIR/checkpoints" \
  "$MODELS_DIR/text_encoders" \
  "$MODELS_DIR/diffusion_models" \
  "$MODELS_DIR/clip_vision" \
  "$MODELS_DIR/clip" \
  "$MODELS_DIR/loras" \
  "$MODELS_DIR/controlnet" \
  "$MODELS_DIR/upscale_models" \
  "$MODELS_DIR/vae" \
  "$MODELS_DIR/ultralytics" \
  "$MODELS_DIR/sxlabs/controlnets" \
  "$MODELS_DIR/style_models" \
  "$MODELS_DIR/liveportrait" \
  "$MODELS_DIR/sams" \
  "$MODELS_DIR/unet"

GIT_REPOS=(
  ".:https://huggingface.co/Aitrepreneur/Florence-2-large"
  ".:https://huggingface.co/Aitrepreneur/llava-llama-3-8b-text-encoder-tokenizer"
  "clip:https://huggingface.co/Aitrepreneur/clip-vit-large-patch14"
  "ultralytics:https://huggingface.co/Aitrepreneur/bbox"
  "ultralytics:https://huggingface.co/Aitrepreneur/segm"
)

# usually files to be downloaded inside git cloned directories
CUSTOM=(
  "Florence-2-large:https://huggingface.co/Aitrepreneur/test/resolve/main/pytorch_model.bin"
  "llava-llama-3-8b-text-encoder-tokenizer:https://huggingface.co/Aitrepreneur/FLX/resolve/main/model-00001-of-00004.safetensors"
  "llava-llama-3-8b-text-encoder-tokenizer:https://huggingface.co/Aitrepreneur/FLX/resolve/main/model-00002-of-00004.safetensors"
  "llava-llama-3-8b-text-encoder-tokenizer:https://huggingface.co/Aitrepreneur/FLX/resolve/main/model-00003-of-00004.safetensors"
  "llava-llama-3-8b-text-encoder-tokenizer:https://huggingface.co/Aitrepreneur/FLX/resolve/main/model-00004-of-00004.safetensors"
  "clip/clip-vit-large-patch14:https://huggingface.co/Aitrepreneur/test/resolve/main/model.safetensors"
  "xlabs/controlnets:https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux-canny-controlnet-v3.safetensors"
  "xlabs/controlnets:https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux-depth-controlnet-v3.safetensors"
  "xlabs/controlnets:https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux-hed-controlnet-v3.safetensors"
  "ultralytics:https://huggingface.co/Aitrepreneur/FLX/resolve/main/face_yolov8n.pt"
)

CHECKPOINTS=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/ltx-video-2b-v0.9-fp8_e4m3fn.safetensors"
  "https://huggingface.co/comfyanonymous/hunyuan_dit_comfyui/resolve/main/hunyuan_dit_1.2.safetensors"
  "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors"
  "https://huggingface.co/fal/AuraFlow-v0.2/resolve/main/aura_flow_0.2.safetensors"
  "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
  "https://huggingface.co/kekusprod/WAI-NSFW-illustrious-SDXL-v110-GGUF/resolve/main/WAI-NSFW-illustrious-SDXL-v110-Q8_0.gguf"
  "https://huggingface.co/guy39/wai-nsfw-illustrious-sdxl-v11.0/resolve/main/waiNSFWIllustrious_v110.safetensors"
)

UNET=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-dev-fp8.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-dev-Q8_0.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-schnell-Q8_0.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-fill-dev_fp8.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-fill-dev-Q8_0.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-canny-dev-fp8.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-canny-dev-fp16-Q8_0-GGUF.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-depth-dev-fp8.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-depth-dev-fp16-Q8_0-GGUF.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/ltx-video-2b-v0.9-Q8_0.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/hunyuan-video-t2v-720p-Q8_0.gguf"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/fast-hunyuan-video-t2v-720p-Q8_0.gguf"
)

UPSCALE_MODELS=(
  "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/a86fc6182b4650b4459cb1ddcb0a0d1ec86bf3b0/RealESRGAN_x2.pth"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/4x-ClearRealityV1.pth"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/RealESRGAN_x4plus_anime_6B.pth"
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
  "https://huggingface.co/Aitrepreneur/FLX/resolve/2b03fd4a8280bda491f5e54e96ad38fd8ab7336b/ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF.safetensors"
)

DIFFUSION_MODELS=(
  "https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors"
  "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors"
  "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
  "https://huggingface.co/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors"
  "https://huggingface.co/black-forest-labs/FLUX.1-Depth-dev/resolve/main/flux1-depth-dev.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/diffusion_models/hidream_i1_dev_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/diffusion_models/hidream_i1_full_fp16.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/hunyuan_video_720_cfgdistill_fp8_e4m3fn.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"
)

CLIP_VISION=(
  "https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/clip_vision/llava_llama3_vision.safetensors"
  "https://huggingface.co/comfyanonymous/clip_vision_g/resolve/main/clip_vision_g.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/sigclip_vision_patch14_384.safetensors"
)

CLIP=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/longclip-L.pt"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/clip_l.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/llava_llama3_fp8_scaled.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/t5xxl_fp8_e4m3fn.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/t5xxl_fp16.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/t5-v1_1-xxl-encoder-Q8_0.gguf"
)

VAE=(
  "https://huggingface.co/Comfy-Org/HiDream-I1_ComfyUI/resolve/main/split_files/vae/ae.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/ae.sft"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/LTX_vae.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/hunyuan_video_vae_bf16.safetensors"
)

LORAS=(
  "https://huggingface.co/black-forest-labs/FLUX.1-Canny-dev-lora/resolve/main/flux1-canny-dev-lora.safetensors"
  "https://huggingface.co/black-forest-labs/FLUX.1-Depth-dev-lora/resolve/main/flux1-depth-dev-lora.safetensors"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/csetiarcane-nfjinx-v1-6000.safetensors"
)

CONTROLNET=(
  "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-canny-controlnet-v3.safetensors"
  "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-depth-controlnet-v3.safetensors"
  "https://huggingface.co/brad-twinkl/controlnet-union-sdxl-1.0-promax/resolve/main/diffusion_pytorch_model.safetensors|controlnet-union-sdxl-1.0-promax.safetensors"
  "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth"
  "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth"
  "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth"
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/Shakker-LabsFLUX1-dev-ControlNet-Union-Pro.safetensors"
)

STYLE_MODELS=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/flux1-redux-dev.safetensors"
)

SAMS=(
  "https://huggingface.co/Aitrepreneur/FLX/resolve/main/sam_vit_b_01ec64.pth"
)

# --- Helpers ---
git_clone_or_update() {
  local target="$1"
  shift
  local repo="$1"
  if [ -d "$target/.git" ]; then
    echo "Updating $(basename "$target")..."
    (cd "$target" && git pull --quiet) || echo "Warning: git pull failed in $target"
  else
    echo "Cloning $(basename "$repo")..."
    git clone "$repo" "$target"
  fi
}
# ---------------------------------------------
# download_list: fetch URLs, optional rename, and continue on error
# ---------------------------------------------
download_list() {
  # Usage: download_list <array_name> <subdir>
  local arr_name="$1[@]"
  local target_dir="$MODELS_DIR/$2"

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

# Clone or update git repos
echo

echo "== Cloning/updating GIT_REPOS =="
for entry in "${GIT_REPOS[@]}"; do
  path=${entry%%:*}
  url=${entry#*:}
  target_dir="$MODELS_DIR/${path}"
  mkdir -p "$target_dir"
  git_clone_or_update "$target_dir" "$url"
done

# Download custom files
echo

echo "== Downloading CUSTOM files =="
for entry in "${CUSTOM[@]}"; do
  path=${entry%%:*}
  url=${entry#*:}
  target_dir="$MODELS_DIR/${path}"
  mkdir -p "$target_dir"
  echo "[INFO] Downloading custom file from $url to $target_dir"
  wget -nc "$url" -P "$target_dir" ||
    echo "[WARNING] Failed to download custom file $url"
done

# ---------------------------------------------
# Execute downloads for each model type
# ---------------------------------------------
echo

for list_name in CHECKPOINTS DIFFUSION_MODELS CLIP CLIP_VISION LORAS UNET SAMS STYLE_MODELS UPSCALE_MODELS TEXT_ENCODERS VAE CONTROLNET; do
  echo "== Downloading $list_name"
  # Pass lowercase list_name as subdirectory
  subdir=$(echo "$list_name" | tr '[:upper:]' '[:lower:]')
  download_list "$list_name" $subdir
done

# Done
echo
echo "== Model initialization complete =="
