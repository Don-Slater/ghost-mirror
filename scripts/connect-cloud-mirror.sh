#!/usr/bin/env bash
# SSH into Ease Mirror Cloud (Hostinger VPS) — one quick command, then exit.
set -euo pipefail

ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
fi

IP="${EASE_MIRROR_CLOUD_IP:-72.62.212.87}"
USER="${EASE_MIRROR_CLOUD_USER:-root}"
KEY="${EASE_MIRROR_SSH_KEY:-${HOME}/.ssh/ben_remote_ubuntu_ed25519}"

# Non-interactive quick check (does not hang terminal)
if [[ "${1:-}" == "--check" ]]; then
  ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    "${USER}@${IP}" 'echo OK; uptime; pgrep -x Xtigervnc >/dev/null && echo VNC:up || echo VNC:down'
  exit 0
fi

echo "Ease Mirror Cloud → ${USER}@${IP}  (type exit to close)"
exec ssh -i "$KEY" -o StrictHostKeyChecking=accept-new "${USER}@${IP}"
