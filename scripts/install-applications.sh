#!/usr/bin/env bash
# Build Ease Mirror and install to /Applications.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ease Mirror"
SRC="${ROOT}/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

bash "${ROOT}/scripts/build.sh" --release

if [[ ! -d "$SRC" ]]; then
  echo "Build failed — no app at $SRC" >&2
  exit 1
fi

if [[ -d "$DEST" ]]; then
  rm -rf "$DEST"
fi

ditto "$SRC" "$DEST"
echo ""
echo "Installed: $DEST"
echo "Launch:    open \"$DEST\""
