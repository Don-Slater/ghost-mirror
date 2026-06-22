#!/usr/bin/env bash
# SSH tunnel for Ease Mirror Cloud — noVNC + VNC on localhost (secure, Linux-native).
set -euo pipefail

ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
PID_FILE="${HOME}/.ben_studio/ease_mirror_vnc_tunnel.pid"

IP="${1:-}"
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/ben_remote_ubuntu_ed25519"

if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
  IP="${IP:-${EASE_MIRROR_CLOUD_IP:-}}"
  SSH_USER="${EASE_MIRROR_CLOUD_USER:-root}"
  SSH_KEY="${EASE_MIRROR_SSH_KEY:-$SSH_KEY}"
fi

IP="${IP:-72.62.212.87}"

stop_tunnel() {
  pkill -f "ssh.*${IP}.*6080" 2>/dev/null || true
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
}

case "${2:-start}" in
  stop)
    stop_tunnel
    echo "Ease Mirror tunnel stopped."
    exit 0
    ;;
  status)
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "running pid=$(cat "$PID_FILE")"
    elif curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
      echo "running (port 6080 in use)"
    else
      echo "stopped"
    fi
    exit 0
    ;;
esac

if curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
  echo "Ease Mirror tunnel already up → http://127.0.0.1:6080/vnc.html"
  exit 0
fi

stop_tunnel
ssh -f -i "$SSH_KEY" \
  -o StrictHostKeyChecking=accept-new \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=6 \
  -N \
  -L "127.0.0.1:6080:127.0.0.1:6080" \
  -L "127.0.0.1:5901:127.0.0.1:5901" \
  "${SSH_USER}@${IP}"

sleep 2

if ! curl -sf -o /dev/null "http://127.0.0.1:6080/vnc.html" 2>/dev/null; then
  echo "Tunnel failed — check SSH: ssh -i $SSH_KEY ${SSH_USER}@${IP}"
  exit 1
fi

TPID="$(lsof -t -iTCP:6080 -sTCP:LISTEN 2>/dev/null | head -1 || true)"
if [[ -n "$TPID" ]]; then
  echo "$TPID" > "$PID_FILE"
fi

echo "Ease Mirror tunnel OK → http://127.0.0.1:6080/vnc.html"
[[ -n "$TPID" ]] && echo "PID ${TPID} — stop with: $0 ${IP} stop"
