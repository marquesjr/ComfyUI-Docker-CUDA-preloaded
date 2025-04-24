#!/bin/bash
set -uo pipefail
shopt -s extglob

# Add error handling
trap 'echo "Error at line $LINENO. Command: $BASH_COMMAND"' ERR

# Source common configuration
source /usr/local/bin/config.sh

# Estimated space needed (adjust as needed)
ESTIMATED_SPACE=250000 # 250GB in MB
check_disk_space "$ESTIMATED_SPACE" || log "WARN" "Continuing with download, but you may run out of disk space"

# 1) Define all your "regular" sections once
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
  PULID
  IPADAPTER
)

# Special lists
GIT_REPOS=()
CUSTOM=()

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
log "INFO" "Parsing configuration from /app/models.conf"
current=""
while IFS= read -r line; do
  # strip comments/spaces
  line="${line%%[#;]*}"
  line="${line##+([[:space:]])}"
  line="${line%%+([[:space:]])}"
  [[ -z "$line" ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current="${BASH_REMATCH[1]}"
    log "INFO" "Processing section: $current"
    continue
  fi

  # only populate if it's one of our LIST_NAMES
  for name in "${LIST_NAMES[@]}"; do
    if [[ "$current" == "$name" ]]; then
      eval "${name}+=(\"$line\")"
      break
    fi
  done

  for name in GIT_REPOS CUSTOM; do
    if [[ "$current" == "$name" ]]; then
      eval "${name}+=(\"$line\")"
      break
    fi
  done
done </app/models.conf

# Download list with improved error handling
download_list() {
  # Usage: download_list <array_name> <subdir>
  local arr_name="$1[@]"
  local target_dir="$MODELS_DIR/$2"
  local total_count=0
  local skipped_count=0
  local downloaded_count=0
  local failed_count=0

  # Count elements in the array
  for entry in "${!arr_name}"; do
    ((total_count++))
  done

  log "INFO" "Starting download for $2 ($total_count items)"
  mkdir -p "$target_dir"

  local current=0
  for entry in "${!arr_name}"; do
    ((current++))
    # split URL and optional new filename (after '|')
    local url="${entry%%|*}"
    local name_part="${entry#*|}"
    local filename
    if [[ "$entry" == *"|"* ]]; then
      filename="$name_part"
    else
      filename="$(basename "$url")"
    fi

    local target_file="$target_dir/$filename"

    # Skip if file exists and is not empty
    if [ -f "$target_file" ] && [ -s "$target_file" ]; then
      log "INFO" "[$current/$total_count] Skipping existing file: $2/$filename"
      ((skipped_count++))
      continue
    fi

    log "INFO" "[$current/$total_count] Downloading: $filename"
    if ! download_with_retry "$url" "$target_file"; then
      log "WARN" "Failed to download $url, continuing with next item"
      # Remove empty/partial files
      [ -f "$target_file" ] && [ ! -s "$target_file" ] && rm "$target_file"
      ((failed_count++))
    else
      ((downloaded_count++))
    fi
  done

  # Print summary
  log "INFO" "Download summary for $2: Total=$total_count, Downloaded=$downloaded_count, Skipped=$skipped_count, Failed=$failed_count"
}

# Clone or update git repos with better progress indication
log "INFO" "== Processing Git Repositories =="
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

  log "INFO" "Processing repo: $url into $target_dir"
  mkdir -p "$base_dir"

  if [ -d "$target_dir" ] && [ ! -d "$target_dir/.git" ]; then
    log "INFO" "Directory exists but is not a git repo, skipping: $target_dir"
    continue
  fi

  if ! git_clone_or_update "$target_dir" "$url"; then
    log "WARN" "Failed to process git repo: $url, continuing with next item"
  fi
done

# Download custom files
log "INFO" "== Processing Custom Files =="
for entry in "${CUSTOM[@]}"; do
  path=${entry%%:*}
  url=${entry#*:}
  target_dir="$MODELS_DIR/${path}"
  mkdir -p "$target_dir" 2>/dev/null
  filename=$(basename "$url")
  target_file="$target_dir/$filename"

  if [ -f "$target_file" ] && [ -s "$target_file" ]; then
    log "INFO" "Skipping existing custom file: $filename"
    continue
  fi

  log "INFO" "Downloading custom file: $url to $target_dir"
  if ! download_with_retry "$url" "$target_file"; then
    log "WARN" "Failed to download custom file: $url"
  fi
done

# Download each model type
for name in "${LIST_NAMES[@]}"; do
  subdir="${name,,}"
  log "INFO" "== Processing $name models =="
  download_list "$name" "$subdir" || {
    error_code=$?
    log "ERROR" "Failed to process $name models, error code: $error_code"
    # Continue instead of failing the whole script
    continue
  }
done

# Done
log "INFO" "== Model initialization complete =="
