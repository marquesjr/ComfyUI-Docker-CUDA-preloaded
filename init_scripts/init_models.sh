#!/bin/bash
set -euo pipefail
shopt -s extglob

# Directories
MODELS_DIR="/app/ComfyUI/models"

# declare special lists
GIT_REPOS=()
CUSTOM=() # usually files to be downloaded inside git cloned directories

# 1) Define all your “regular” sections once
LIST_NAMES=(
  CHECKPOINTS
  DIFFUSION_MODELS
  CLIP
  CLIP_VISION
  LORAS
  UNET
  SAMS
  STYLE_MODELS
  UPSCALE_MODELS
  TEXT_ENCODERS
  VAE
  CONTROLNET
)

# 2) Declare empty arrays for each
for name in "${LIST_NAMES[@]}"; do
  eval "declare -a ${name}=()"
done

# 3) Make all subdirs in one loop
for name in "${LIST_NAMES[@]}"; do
  subdir="${name,,}" # lowercase
  mkdir -p "$MODELS_DIR/$subdir"
done

# 4) Parse your INI config (models.conf) into those arrays
current=""
while IFS= read -r line; do
  # strip comments/spaces
  line="${line%%[#;]*}"
  line="${line##+([[:space:]])}"
  line="${line%%+([[:space:]])}"
  [[ -z "$line" ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current="${BASH_REMATCH[1]}"
    continue
  fi

  # only populate if it’s one of our LIST_NAMES
  for name in "${LIST_NAMES[@]}"; do
    if [[ "$current" == "$name" ]]; then
      eval "${name}+=(\"$line\")"
      break
    fi
  done
done </app/models.conf

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
  raw_path=${entry%%:*}
  url=${entry#*:}

  # Determine base directory: models dir or subfolder
  if [ "$raw_path" = "." ]; then
    base_dir="$MODELS_DIR"
  else
    base_dir="$MODELS_DIR/$raw_path"
  fi

  # Repo name is the basename of the URL
  repo_name=$(basename "$url" .git)
  target_dir="$base_dir/$repo_name"

  echo "[INFO] Processing repo $url into $target_dir"

  if [ -d "$target_dir/.git" ]; then
    # Repo exists: update
    echo "[INFO] Updating existing repo in $target_dir"
    git -C "$target_dir" pull --rebase --quiet ||
      (git -C "$target_dir" fetch --quiet && git -C "$target_dir" reset --hard --quiet)
  elif [ -d "$target_dir" ]; then
    # Directory exists but no git metadata: skip cloning
    echo "[INFO] Directory $target_dir exists and is not a git repo, skipping clone"
  else
    # Ensure base directory exists
    mkdir -p "$base_dir"
    # Directory doesn't exist: clone
    echo "[INFO] Cloning $url into $target_dir"
    git clone --quiet "$url" "$target_dir"
  fi

  echo
done

# Download custom files
echo

echo "== Downloading CUSTOM files =="
for entry in "${CUSTOM[@]}"; do
  path=${entry%%:*}
  url=${entry#*:}
  target_dir="$MODELS_DIR/${path}"
  mkdir -p "$target_dir" 2>/dev/null
  echo "[INFO] Downloading custom file from $url to $target_dir"
  wget -nc "$url" -P "$target_dir" ||
    echo "[WARNING] Failed to download custom file $url"
done

# ---------------------------------------------
# Execute downloads for each model type
# ---------------------------------------------
echo

# 5) Now download each
for name in "${LIST_NAMES[@]}"; do
  subdir="${name,,}"
  echo "== Downloading $name into models/$subdir =="
  download_list "$name" "$subdir"
done

# Done
echo
echo "== Model initialization complete =="
