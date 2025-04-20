#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# init_extensions.sh (full list with error handling)
# ---------------------------------------------

# Base ComfyUI directories
COMFY_DIR="${COMFYUI_DIR:-/app/ComfyUI}"
CUSTOM_DIR="$COMFY_DIR/custom_nodes"

# --- Helpers ---
ccd() {
  mkdir -p "$1"
  cd "$1"
}

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

download_hf_file() {
  local repo="$1"
  local file="$2"
  if [ -f "$file" ]; then
    echo "  $file exists, skipping."
  else
    echo "  Downloading $file from $repo..."
    if ! huggingface-cli download "$repo" "$file" --local-dir .; then
      echo "  Warning: failed to download $file from $repo"
    fi
  fi
}

download_hf_files() {
  local repo="$1"
  shift
  for f in "$@"; do
    download_hf_file "$repo" "$f"
  done
}

# ---------------------------------------------
# 1) Clone/update ComfyUI extensions
# ---------------------------------------------
extensions=(
  "https://github.com/ltdrdata/ComfyUI-Manager.git"
  "https://codeberg.org/Gourieff/comfyui-reactor-node.git"
  "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
  "https://github.com/kijai/ComfyUI-LivePortraitKJ.git"
  "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git"
  "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
  "https://github.com/kijai/ComfyUI-KJNodes.git"
  "https://github.com/city96/ComfyUI-GGUF.git"
  "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
  "https://github.com/kijai/ComfyUI-Florence2.git"
  "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
  "https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced.git"
  "https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git"
  "https://github.com/wallish77/wlsh_nodes.git"
  "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
  "https://github.com/rgthree/rgthree-comfy.git"
  "https://github.com/WASasquatch/was-node-suite-comfyui.git"
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
  "https://github.com/TinyTerra/ComfyUI_tinyterraNodes.git"
  "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git"
  "https://github.com/Smirnov75/ComfyUI-mxToolkit.git"
  "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
  "https://github.com/cubiq/ComfyUI_essentials.git"
  "https://github.com/chrisgoringe/cg-use-everywhere.git"
  "https://github.com/XLabs-AI/x-flux-comfyui.git"
  "https://github.com/logtd/ComfyUI-LTXTricks.git"
  "https://github.com/SeaArtLab/ComfyUI-Long-CLIP.git"
  "https://github.com/jamesWalker55/comfyui-various.git"
  "https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git"
  "https://github.com/palant/image-resize-comfyui.git"
  "https://github.com/BlenderNeko/ComfyUI_Noise.git"
  "https://github.com/LEv145/images-grid-comfy-plugin.git"
  "https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git"
  "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
)

echo "\n== Cloning/updating extensions in $CUSTOM_DIR =="
mkdir -p "$CUSTOM_DIR"
for url in "${extensions[@]}"; do
  name=$(basename "$url" .git)
  git_clone_or_update "$CUSTOM_DIR/$name" "$url"
done

# Install extension Python deps if present
for ext in "$CUSTOM_DIR"/*; do
  if [ -f "$ext/requirements.txt" ]; then
    echo "Installing deps for $(basename "$ext")..."
    pip install --no-cache-dir -r "$ext/requirements.txt" || echo "Warning: pip install failed for $ext"
  fi
done

# ---------------------------------------------
# ---------------------------------------------
# 2) Process all HuggingFace model sets
# ---------------------------------------------
HF_MODEL_SETS=(
  "Aitrepreneur/insightface:insightface:"
  "Aitrepreneur/Florence-2-base:LLM/Florence-2-base:pytorch_model.bin"
  "microsoft/Florence-2-large:LLM/Florence-2-large:pytorch_model.bin"
  #"Aitrepreneur/llava-llama-3-8b-text-encoder-tokenizer:LLM/llava-llama-3-8b-text-encoder-tokenizer:model-00001-of-00004.safetensors model-00002-of-00004.safetensors model-00003-of-00004.safetensors model-00004-of-00004.safetensors"
  "Aitrepreneur/test:clip/clip-vit-large-patch14:model.safetensors"
  "Aitrepreneur/FLX:clip:longclip-L.pt clip_l.safetensors"
  "Aitrepreneur/FLX:clip_vision:sigclip_vision_patch14_384.safetensors"
  "Aitrepreneur/FLX:checkpoints:ltx-video-2b-v0.9-fp8_e4m3fn.safetensors"
  "Aitrepreneur/FLX:controlnet:diffusion_pytorch_model_promax.safetensors Shakker-LabsFLUX1-dev-ControlNet-Union-Pro.safetensors"
  "Aitrepreneur/FLX:diffusion_models:hunyuan_video_720_cfgdistill_fp8_e4m3fn.safetensors hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"
  "Aitrepreneur/FLX:vae:ae.sft LTX_vae.safetensors hunyuan_video_vae_bf16.safetensors"
  "Aitrepreneur/FLX:xlabs/controlnets:flux-canny-controlnet-v3.safetensors flux-depth-controlnet-v3.safetensors flux-hed-controlnet-v3.safetensors"
  "Aitrepreneur/FLX:upscale_models:4x-ClearRealityV1.pth RealESRGAN_x4plus_anime_6B.pth"
  "Aitrepreneur/FLX:style_models:flux1-redux-dev.safetensors"
  "Aitrepreneur/FLX:loras:csetiarcane-nfjinx-v1-6000.safetensors"
  "Aitrepreneur/FLX:liveportrait:landmark.onnx"
  "Aitrepreneur/FLX:sams:sam_vit_b_01ec64.pth"
)

echo "
== Processing HF_MODEL_SETS =="
for entry in "${HF_MODEL_SETS[@]}"; do
  IFS=":" read -r REPO DIR FILES <<<"$entry"
  # clone repo if no FILES
  if [[ -z "$FILES" ]]; then
    echo "Cloning full HF repo $REPO into models/$DIR..."
    git_clone_or_update "$COMFY_DIR/models/$DIR" "https://huggingface.co/$REPO"
  fi

  # download specified files
  if [[ -n "$FILES" ]]; then
    TARGET="$COMFY_DIR/models/$DIR"
    mkdir -p "$TARGET"
    cd "$TARGET"
    echo "Downloading files for $REPO into models/$DIR: $FILES"
    download_hf_files "$REPO" $FILES
  fi
done

# ---------------------------------------------
# Done
# ---------------------------------------------
echo "
Extensions and HF models initialization complete."
