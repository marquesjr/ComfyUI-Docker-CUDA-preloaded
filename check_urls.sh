#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage: ./check_urls.sh [config_file]
# Defaults to models.conf if no argument is given.
readonly DEFAULT_CONF="models.conf"

# print usage and exit
usage() {
  cat <<EOF >&2
Usage: $(basename "$0") [config_file]
  config_file  Path to your models.conf (default: $DEFAULT_CONF)
EOF
  exit 1
}

# extract unique URLs from the given file (strips any "|rename" suffix)
extract_urls() {
  local file="$1"
  grep -Eo 'https?://[^|[:space:]]+' "$file" |
    sort -u
}

# perform a HEAD request and return HTTP status (or "000" on network error)
check_url() {
  local url="$1"
  local status
  if status=$(curl -sSL -I -o /dev/null -w "%{http_code}" "$url"); then
    echo "$status"
  else
    echo "000"
  fi
}

main() {
  local conf="${1:-$DEFAULT_CONF}"
  [[ -f "$conf" ]] || {
    echo "Config file '$conf' not found."
    usage
  }

  # read URLs into an array
  mapfile -t urls < <(extract_urls "$conf")
  local total=${#urls[@]}
  local -a successes=()
  local -a failures=()

  echo "Checking $total URLs from '$conf'…"
  echo

  for url in "${urls[@]}"; do
    local code
    code=$(check_url "$url")
    if [[ "$code" -eq 200 ]]; then
      printf "✓ %s → %s\n" "$url" "$code"
      successes+=("$url")
    else
      printf "✗ %s → %s\n" "$url" "$code"
      failures+=("$url")
    fi
  done

  # summary
  echo
  echo "Summary:"
  printf "  Total URLs : %d\n" "$total"
  printf "  Succeeded  : %d\n" "${#successes[@]}"
  printf "  Failed     : %d\n" "${#failures[@]}"

  if ((${#failures[@]} > 0)); then
    echo
    echo "Failed URLs:"
    for u in "${failures[@]}"; do
      echo "  - $u"
    done
  fi
}

# run
main "$@"
