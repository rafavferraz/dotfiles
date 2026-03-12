#!/bin/bash

echo "=== Authenticating with GitHub ==="
if ! gh auth status &>/dev/null; then
    gh auth login
fi
