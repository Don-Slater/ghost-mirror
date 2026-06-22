#!/usr/bin/env bash
# Clipboard setup — ONLY after Mark Installed + VM restarted in Ease Mirror app.
set -euo pipefail

TAG="EaseMirrorShare"
MOUNT="${EASE_MIRROR_SHARE_MOUNT:-$HOME/EaseMirrorShare}"

echo "Ease Mirror — clipboard setup"
echo ""

# VirtioFS device only exists after Mark Installed + Stop + Start on Mac.
if ! (ls "/sys/fs/virtiofs/${TAG}" >/dev/null 2>&1 || \
      ls /dev/virtiofs/* 2>/dev/null | grep -qi ease; \
      find /sys -maxdepth 4 -name "*${TAG}*" 2>/dev/null | grep -q .); then
  echo "STOP — share not available yet (this causes kernel panic if forced)."
  echo ""
  echo "On Mac first:"
  echo "  1. Finish Ubuntu install (desktop working)"
  echo "  2. Stop VM"
  echo "  3. Click Mark Installed"
  echo "  4. Start again"
  echo "  5. Then run this script"
  exit 1
fi

sudo apt-get update -qq
sudo apt-get install -y -qq xclip

mkdir -p "$MOUNT"
if ! mountpoint -q "$MOUNT" 2>/dev/null; then
  if ! sudo mount -t virtiofs "$TAG" "$MOUNT" 2>/dev/null; then
    echo "Mount failed — Mark Installed on Mac, Stop, Start, try again."
    exit 1
  fi
fi

SCRIPT="$MOUNT/ease-mirror-clipboard-guest.sh"
if [[ ! -x "$SCRIPT" ]]; then
  echo "Script missing at $SCRIPT — restart VM on Mac after Mark Installed."
  exit 1
fi

bash "$SCRIPT" stop 2>/dev/null || true
bash "$SCRIPT" start
echo ""
echo "OK — copy Mac, paste Linux (Ctrl+V). Copy Linux, paste Mac (Cmd+V)."
