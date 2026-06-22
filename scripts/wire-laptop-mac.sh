#!/usr/bin/env bash
# Ghost Mirror — wire cloud laptop from Mac (one command).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
IP="72.62.212.87"
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/ben_remote_ubuntu_ed25519"
APP_URL="https://ghostcloud.srv1699052.hstgr.cloud"

if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
  IP="${EASE_MIRROR_CLOUD_IP:-$IP}"
  SSH_USER="${EASE_MIRROR_CLOUD_USER:-$SSH_USER}"
  SSH_KEY="${EASE_MIRROR_SSH_KEY:-$SSH_KEY}"
fi

if [[ -f "${HOME}/.ben_studio/ghostcloud_remote.env" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.ben_studio/ghostcloud_remote.env"
  APP_URL="${GHOSTCLOUD_APP_URL:-$APP_URL}"
fi

echo "=== Ghost Mirror — wire laptop from Mac ==="
echo "Node: ${SSH_USER}@${IP}"

scp -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new \
  "${ROOT}/scripts/wire-laptop-cloud.sh" \
  "${SSH_USER}@${IP}:/tmp/wire-laptop-cloud.sh"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${IP}" \
  "chmod +x /tmp/wire-laptop-cloud.sh && GHOST_USER=${SSH_USER} GHOST_MIRROR_APP_URL=${APP_URL} bash /tmp/wire-laptop-cloud.sh"

mkdir -p "${HOME}/.ben_studio"
cat >>"${HOME}/.ben_studio/ease_mirror_cloud.env" 2>/dev/null <<ENV || true
EASE_MIRROR_GHOST_URL=${APP_URL}
EASE_MIRROR_CLOUD_IP=${IP}
ENV

echo ""
echo "Opening Ghost Mirror on Mac…"
open "${APP_URL}/bridge"
open "${APP_URL}/library"

if [[ "${1:-}" == "--desktop" ]]; then
  bash "${ROOT}/scripts/connect-cloud-desktop.sh"
fi

echo ""
echo "Done. Cloud Linux is wired like a laptop."
echo "  Terminal: ${APP_URL}/bridge"
echo "  Vault:    ${APP_URL}/library"
echo "  Desktop:  bash ${ROOT}/scripts/connect-cloud-desktop.sh"
