#!/usr/bin/env bash
# Provision Cloud Mirror on a VPS — Ubuntu + Ghost Cloud node.
set -euo pipefail

IP="${1:-}"
if [[ -z "$IP" ]]; then
  echo "Usage: provision-cloud-mirror.sh <vps-ip>"
  exit 1
fi

BEN="${HOME}/BenStudio"
HOSTINGER_ENV="${HOME}/.ben_studio/hostinger.env"
HOSTINGER="${BEN}/scripts/remote-ubuntu/setup-hostinger.sh"
GC_NODE="${BEN}/scripts/ghostcloud-remote/bootstrap-ghostcloud-node.sh"
WIRE="${BEN}/EaseMirror/scripts/wire-ghost-home.sh"
SSH_KEY="${HOME}/.ssh/ben_remote_ubuntu_ed25519"
SSH_USER="root"

if [[ -f "$HOSTINGER_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$HOSTINGER_ENV"
  SSH_USER="${HOSTINGER_USER:-root}"
  SSH_KEY="${HOSTINGER_SSH_KEY:-$SSH_KEY}"
fi

echo "=== Ease Mirror Cloud — $IP (${SSH_USER}) ==="

if ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
  "${SSH_USER}@${IP}" 'echo connected' &>/dev/null; then
  echo "SSH key auth OK"
else
  if [[ -f "$HOSTINGER" ]]; then
    bash "$HOSTINGER" "$IP"
  else
    echo "SSH failed — add your key in Hostinger hPanel or run prepare-mac.sh"
    exit 1
  fi
fi

if [[ -f "$GC_NODE" ]] && ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new \
  "${SSH_USER}@${IP}" 'systemctl is-active ghostcloud-ipfs' &>/dev/null; then
  scp -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "$GC_NODE" "${SSH_USER}@${IP}:/tmp/bootstrap-ghostcloud-node.sh"
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${IP}" \
    "GHOST_USER=${SSH_USER} bash /tmp/bootstrap-ghostcloud-node.sh"
fi

if [[ -f "$WIRE" ]]; then
  scp -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "$WIRE" "${SSH_USER}@${IP}:/tmp/wire-ghost-home.sh"
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${IP}" \
    "GHOST_USER=${SSH_USER} bash /tmp/wire-ghost-home.sh"
fi

mkdir -p "${HOME}/.ben_studio"
cat >"${HOME}/.ben_studio/ease_mirror_cloud.env" <<ENV
EASE_MIRROR_CLOUD_IP=${IP}
EASE_MIRROR_CLOUD_USER=${SSH_USER}
EASE_MIRROR_SSH_KEY=${SSH_KEY}
EASE_MIRROR_HOST=srv1699052.hstgr.cloud
EASE_MIRROR_GHOST_URL=https://ghostcloud.srv1699052.hstgr.cloud
EASE_MIRROR_WIRED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ENV

cat >"${HOME}/.ben_studio/ghostcloud_remote.env" <<ENV
GHOSTCLOUD_REMOTE_IP=${IP}
GHOSTCLOUD_REMOTE_USER=${SSH_USER}
GHOSTCLOUD_SSH_KEY=${SSH_KEY}
GHOSTCLOUD_IPFS_API=/ip4/127.0.0.1/tcp/5001
GHOSTCLOUD_APP_URL=https://ghostcloud.srv1699052.hstgr.cloud
ENV

echo ""
echo "Cloud Mirror ready at ${IP}"
echo "  SSH:     bash ${BEN}/EaseMirror/scripts/connect-cloud-mirror.sh"
echo "  Ghost:   ${GHOSTCLOUD_APP_URL:-https://ghostcloud.srv1699052.hstgr.cloud}"
echo "  Tunnel:  bash ${BEN}/scripts/ghostcloud-remote/tunnel.sh ${IP}"
echo "  GhostHome: /root/GhostHome on VPS"
