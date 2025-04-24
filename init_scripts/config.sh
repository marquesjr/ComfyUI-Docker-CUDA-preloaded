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

# Download with retry and resume capability - with periodic updates
download_with_retry() {
  local url="$1"
  local output="$2"
  local max_retries=3
  local retry=0
  local timeout=120        # 2 minutes timeout
  local update_interval=10 # Update log every 10 seconds for large files

  while ((retry < max_retries)); do
    log "INFO" "Downloading: $url to $output (attempt $((retry + 1))/$max_retries)"

    # Start wget in background with dot progress (less verbose)
    wget --timeout="$timeout" -q --progress=dot:mega -c -O "$output" "$url" 2>&1 &
    local wget_pid=$!

    # Monitor progress periodically
    local start_time=$(date +%s)
    local success=false

    while kill -0 $wget_pid 2>/dev/null; do
      # Check if enough time passed for an update
      local current_time=$(date +%s)
      local elapsed=$((current_time - start_time))

      if ((elapsed % update_interval == 0)); then
        # Get file size so far
        if [ -f "$output" ]; then
          local size=$(du -h "$output" | cut -f1)
          log "INFO" "Still downloading: $output (Current size: $size, Elapsed: ${elapsed}s)"
        fi
      fi

      sleep 1
    done

    # Check if wget completed successfully
    wait $wget_pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
      # Get final file size
      local final_size=$(du -h "$output" | cut -f1)
      log "INFO" "Download completed: $(basename "$output") (Size: $final_size)"
      return 0
    else
      retry=$((retry + 1))

      # Check for common error conditions
      if [[ $exit_code -eq 6 ]]; then
        log "ERROR" "Authentication required for URL: $url"
        log "ERROR" "Please check the URL or update it in models.conf"
        # Return a specific error code for auth issues
        return 100
      elif [[ $exit_code -eq 8 ]]; then
        log "ERROR" "Server error (HTTP 4xx/5xx) for URL: $url"
        log "ERROR" "URL may be invalid or server is down"
        # Return a specific error code for server issues
        return 101
      fi

      log "WARN" "Download failed (exit code $exit_code), retrying in 5 seconds ($retry/$max_retries): $url"
      sleep 5
    fi
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
