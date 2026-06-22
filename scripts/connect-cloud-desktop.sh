#!/usr/bin/env bash
# Open Ease Mirror Cloud desktop — keeps tunnel alive, password pre-filled.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
IP="72.62.212.87"
VNC_PASS="EaseMirror2026"

if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
  IP="${EASE_MIRROR_CLOUD_IP:-$IP}"
  VNC_PASS="${EASE_MIRROR_VNC_PASSWORD:-$VNC_PASS}"
fi

echo "Starting cloud desktop…"

# Quick VPS health — restart VNC stack if dead
if ! ssh -i "${EASE_MIRROR_SSH_KEY:-$HOME/.ssh/ben_remote_ubuntu_ed25519}" \
  -o BatchMode=yes -o ConnectTimeout=10 "root@${IP}" \
  'pgrep -x Xtigervnc >/dev/null && curl -sf -o /dev/null http://127.0.0.1:6080/vnc.html' 2>/dev/null; then
  echo "Restarting VPS desktop…"
  bash "${ROOT}/scripts/fix-vnc-service.sh" "$IP"
fi

# Tunnel (must stay running while you use desktop)
bash "${ROOT}/scripts/tunnel-cloud-vnc.sh" "$IP" start

# Wait until noVNC reachable through tunnel
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
    break
  fi
  sleep 1
done

if ! curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
  echo "FAIL: tunnel up but noVNC not reachable. Run:"
  echo "  bash ${ROOT}/scripts/fix-vnc-service.sh"
  exit 1
fi

NOVNC="http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale&password=${VNC_PASS}&show_dot=true"

echo "Opening desktop (keep this Mac awake — tunnel runs in background)"
echo "Password if asked: ${VNC_PASS}"
echo ""
echo "Cloud clipboard: in noVNC click the clipboard icon (left bar) to paste Mac text in."
echo ""
echo "To stop tunnel later:"
echo "  bash ${ROOT}/scripts/tunnel-cloud-vnc.sh ${IP} stop"

# Browser is more stable than in-app WebView for noVNC today
open "$NOVNC"
