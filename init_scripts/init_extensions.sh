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
    git clone --recursive --quiet "$url" "$dir" || return 5
  fi

  # Check for new commit
  new_commit=$(git -C "$dir" rev-parse HEAD) || return 6
  old_commit=""
  if [ -f "$last_commit_file" ]; then
    old_commit=$(<"$last_commit_file")
  fi
  if [ "$new_commit" != "$old_commit" ]; then
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
EXTENSIONS=()

while IFS= read -r line; do
  line="${line%%[#;]*}"
  line="${line##+([[:space:]])}"
  line="${line%%+([[:space:]])}"
  [[ -z "$line" || "$line" =~ ^\[ ]] && continue
  EXTENSIONS+=("$line")
done </app/extensions.conf

echo "== Cloning/updating extensions in $CUSTOM_DIR =="
for url in "${EXTENSIONS[@]}"; do
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
