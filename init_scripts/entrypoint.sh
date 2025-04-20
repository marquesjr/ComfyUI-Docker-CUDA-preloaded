#!/bin/bash
set -euo pipefail

# 1) Models first
echo "running init_models.sh"
/usr/local/bin/init_models.sh "$@"

# 2) Then extensions
echo "running init_extensions.sh"
/usr/local/bin/init_extensions.sh "$@"

# 3) Finally launch ComfyUI
echo "running the server"
exec "$@"
