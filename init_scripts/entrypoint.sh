#!/bin/bash
set -euo pipefail

echo "running init_extensions.sh"
/usr/local/bin/init_extensions.sh "$@"

echo "running init_models.sh"
/usr/local/bin/init_models.sh "$@"

echo "running the server"
exec "$@"
