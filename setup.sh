#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$DIR/scripts/folders.sh"
bash "$DIR/scripts/install.sh"
