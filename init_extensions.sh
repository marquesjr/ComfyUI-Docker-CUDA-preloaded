#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# init_extensions.sh (full list with error handling)
# ---------------------------------------------

# Base ComfyUI directories
COMFY_DIR="/app/ComfyUI"
CUSTOM_DIR="$COMFY_DIR/custom_nodes"
LAST_DIR="$CUSTOM_DIR/.last_commits"
# Ensure directories exist
mkdir -p "$CUSTOM_DIR" "$LAST_DIR"

# Function: clone or update a git repo, track last commit centrally
# Usage: git_clone_or_update <target_dir> <git_url>
# Returns: 0 if new clone or updated commit; 1 if unchanged; >1 on error

git_clone_or_update() {
  local dir="$1" url="$2"
  local name=$(basename "$dir")
  local last_commit_file="$LAST_DIR/${name}.commit"
  local new_commit old_commit branch

  if [ -d "$dir/.git" ]; then
    echo "[INFO] Fetching updates for $name"
    git -C "$dir" fetch --quiet || return 2
    branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD) || return 3
    git -C "$dir" reset --hard "origin/$branch" --quiet || return 4
  else
    echo "[INFO] Cloning $name from $url"
    git clone --quiet "$url" "$dir" || return 5
  fi

  new_commit=$(git -C "$dir" rev-parse HEAD) || return 6

  if [ -f "$last_commit_file" ]; then
    old_commit=$(<"$last_commit_file")
  fi

  if [ "$new_commit" != "$old_commit" ]; then
    echo "[INFO] New commit for $name: $new_commit"
    echo "$new_commit" >"$last_commit_file"
    return 0
  else
    echo "[INFO] No changes in $name ($new_commit)"
    return 1
  fi
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

echo "== Cloning/updating extensions in $CUSTOM_DIR =="
for url in "${extensions[@]}"; do
  name=$(basename "$url" .git)
  target="$CUSTOM_DIR/$name"
  if git_clone_or_update "$target" "$url"; then
    if [ -f "$target/requirements.txt" ]; then
      echo "[INFO] Installing deps for $name..."
      pip install --no-cache-dir -r "$target/requirements.txt" ||
        echo "[WARNING] pip install failed for $name"
    fi
  fi
done

# ---------------------------------------------
# Done
# ---------------------------------------------
echo
echo "Extensions initialization complete."
