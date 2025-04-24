#!/bin/bash

# Base directories
COMFY_DIR="/app/ComfyUI"
MODELS_DIR="$COMFY_DIR/models"
CUSTOM_DIR="$COMFY_DIR/custom_nodes"
LAST_DIR="$CUSTOM_DIR/.last_commits"

# Ensure directories exist
mkdir -p "$MODELS_DIR" "$CUSTOM_DIR" "$LAST_DIR"

# Logging function
log() {
  local level="$1"
  local message="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Check available disk space
check_disk_space() {
  local required="$1" # in MB
  local available=$(df -m "$MODELS_DIR" | awk 'NR==2 {print $4}')
  if ((available < required)); then
    log "ERROR" "Not enough disk space. Required: ${required}MB, Available: ${available}MB"
    return 1
  fi
  log "INFO" "Disk space check passed. Required: ${required}MB, Available: ${available}MB"
  return 0
}

# Download with retry and resume capability
download_with_retry() {
  local url="$1"
  local output="$2"
  local max_retries=3
  local retry=0
  local timeout=120 # 2 minutes timeout

  while ((retry < max_retries)); do
    log "INFO" "Downloading: $url to $output (attempt $((retry + 1))/$max_retries)"
    if wget --timeout="$timeout" -q --show-progress -c -O "$output" "$url"; then
      log "INFO" "Download completed: $(basename "$output")"
      return 0
    fi
    retry=$((retry + 1))
    log "WARN" "Download failed, retrying in 5 seconds ($retry/$max_retries): $url"
    sleep 5
  done

  log "ERROR" "Failed to download after $max_retries attempts: $url"
  return 1
}

# Git clone or update with improved error handling
git_clone_or_update() {
  local dir="$1"
  local url="$2"
  local timeout=60 # 1 minute timeout
  local name=$(basename "$dir")

  if [ -d "$dir/.git" ]; then
    log "INFO" "Updating repository: $name"
    if timeout "$timeout" git -C "$dir" fetch --quiet; then
      local branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
      if timeout "$timeout" git -C "$dir" reset --hard "origin/$branch" --quiet; then
        log "INFO" "Successfully updated $name"
        return 0
      else
        log "ERROR" "Failed to reset to origin/$branch in $name"
        return 1
      fi
    else
      log "ERROR" "Git fetch failed for $name"
      return 1
    fi
  else
    log "INFO" "Cloning repository: $url to $dir"
    if timeout "$timeout" git clone --recursive --quiet "$url" "$dir"; then
      log "INFO" "Successfully cloned $name"
      if [ -d "$dir" ]; then
        timeout "$timeout" git -C "$dir" lfs install && git -C "$dir" lfs pull
      fi
      return 0
    else
      log "ERROR" "Git clone failed for $url"
      return 1
    fi
  fi
}
