#!/usr/bin/env bash
# Download Ubuntu 24.04 ARM64 desktop ISO for Ease Mirror local install.
set -euo pipefail

ISO_URL="https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-desktop-arm64.iso"
DEST="${HOME}/Library/Application Support/EaseMirror/ISOs/ubuntu-24.04.4-desktop-arm64.iso"

mkdir -p "$(dirname "$DEST")"
if [[ -f "$DEST" ]]; then
  echo "ISO already exists: $DEST"
  exit 0
fi

echo "Downloading Ubuntu 24.04 ARM64 desktop (~3 GB)…"
curl -L --progress-bar "$ISO_URL" -o "$DEST"
echo "Done: $DEST"
