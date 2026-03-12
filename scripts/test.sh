#!/bin/bash

# Test dotfiles setup on a fresh Ubuntu 24.04 container.
# Usage: bash scripts/test.sh

set -e

# Docker Desktop CLI (macOS)
if [ -d "/Applications/Docker.app/Contents/Resources/bin" ]; then
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Building dotfiles test image ==="
docker build --progress=plain --no-cache -f "$DIR/Dockerfile.test" -t dotfiles-test "$DIR" 2>&1

echo ""
echo "=== Test passed! Setup works on a fresh Ubuntu 24.04. ==="
echo "Cleaning up..."
docker rmi dotfiles-test >/dev/null
echo "Done."
