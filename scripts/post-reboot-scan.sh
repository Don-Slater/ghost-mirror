#!/usr/bin/env bash
# Ease Mirror — full system scan after Mac/VPS reboot.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
IP="72.62.212.87"
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/ben_remote_ubuntu_ed25519"
FAIL=0

pass() { echo "  OK   $1"; }
fail() { echo "  FAIL $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN $1"; }

if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
  IP="${EASE_MIRROR_CLOUD_IP:-$IP}"
  SSH_USER="${EASE_MIRROR_CLOUD_USER:-$SSH_USER}"
  SSH_KEY="${EASE_MIRROR_SSH_KEY:-$SSH_KEY}"
fi

echo ""
echo "============================================"
echo "  Ease Mirror — post-reboot system scan"
echo "  $(date)"
echo "============================================"
echo ""

echo "── Mac ──"
if [[ -x "${ROOT}/Ease Mirror.app/Contents/MacOS/EaseMirror" ]] || [[ -x "/Applications/Ease Mirror.app/Contents/MacOS/EaseMirror" ]]; then
  pass "Ease Mirror.app binary"
else
  fail "Ease Mirror.app missing — run: cd ${ROOT} && ./scripts/build.sh --release"
fi

if [[ -x "${ROOT}/.build/release/ghost-mirror-cli" ]]; then
  pass "ghost-mirror-cli"
else
  warn "CLI not built — run: cd ${ROOT} && swift build -c release"
fi

ISO="${HOME}/Library/Application Support/EaseMirror/ISOs/ubuntu-24.04.4-desktop-arm64.iso"
if [[ -f "$ISO" ]]; then
  pass "Ubuntu ISO downloaded"
else
  warn "ISO not downloaded (Phase B not started — normal)"
fi

echo ""
echo "── VPS (${IP}) ──"
if OUT=$(ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=12 -o StrictHostKeyChecking=accept-new \
  "${SSH_USER}@${IP}" 'echo OK; uptime -p; pgrep -x Xtigervnc >/dev/null && echo VNC:up || echo VNC:down; pgrep -f "websockify.*6080" >/dev/null && echo NOVNC:up || echo NOVNC:down; systemctl is-active ghostcloud-ipfs 2>/dev/null || echo IPFS:down; systemctl is-active ghostcloud-app 2>/dev/null || echo APP:down; test -d /root/GhostHome && echo GHOSTHOME:yes || echo GHOSTHOME:no' 2>&1); then
  echo "$OUT" | while read -r line; do
    case "$line" in
      OK) pass "SSH connected" ;;
      VNC:up) pass "TigerVNC" ;;
      VNC:down) fail "TigerVNC down — run: bash ${ROOT}/scripts/fix-vnc-service.sh" ;;
      NOVNC:up) pass "noVNC websockify" ;;
      NOVNC:down) fail "noVNC down — run: bash ${ROOT}/scripts/fix-vnc-service.sh" ;;
      active) pass "Ghost Cloud service" ;;
      IPFS:down|APP:down) fail "$line" ;;
      GHOSTHOME:yes) pass "GhostHome folder" ;;
      GHOSTHOME:no) fail "GhostHome missing" ;;
      up*) echo "       $line" ;;
      *) [[ -n "$line" ]] && echo "       $line" ;;
    esac
  done
else
  fail "SSH to VPS — $OUT"
fi

echo ""
echo "── Tunnel ──"
TUN="$(bash "${ROOT}/scripts/tunnel-cloud-vnc.sh" "$IP" status 2>&1 || true)"
if echo "$TUN" | grep -q running; then
  pass "VNC tunnel ($TUN)"
elif curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
  pass "noVNC reachable on localhost:6080"
else
  warn "Tunnel stopped (expected after reboot) — run: bash ${ROOT}/scripts/tunnel-cloud-vnc.sh ${IP} start"
fi

echo ""
echo "── Local mirrors ──"
if [[ -x "${ROOT}/.build/release/ghost-mirror-cli" ]]; then
  "${ROOT}/.build/release/ghost-mirror-cli" list 2>/dev/null || true
else
  echo "       (no CLI — skip)"
fi

echo ""
echo "============================================"
if [[ "$FAIL" -eq 0 ]]; then
  echo "  SCAN PASS — tidy. Ready to move forward."
  echo ""
  echo "  Open cloud desktop:"
  echo "    bash ${ROOT}/scripts/connect-cloud-desktop.sh"
  echo ""
  echo "  Or app:"
  echo "    open ${ROOT}/Ease\\ Mirror.app"
else
  echo "  SCAN: ${FAIL} issue(s) — fix FAIL lines above before Phase B."
fi
echo "============================================"
echo ""

exit "$FAIL"
