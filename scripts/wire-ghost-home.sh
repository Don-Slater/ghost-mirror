#!/usr/bin/env bash
# Wire Ghost Home inside Ubuntu guest (run from shared VirtioFS folder or after SSH).
set -euo pipefail

GHOST_USER="${USER:-ubuntu}"
GHOST_HOME="$(getent passwd "$GHOST_USER" 2>/dev/null | cut -d: -f6 || echo "$HOME")"
MIRROR_HOME="${GHOST_HOME}/GhostHome"

echo "=== Ease Mirror — Ghost Home ==="

mkdir -p "$MIRROR_HOME"/{Documents,Downloads,Projects}

if ! command -v ipfs &>/dev/null; then
  echo "Installing IPFS (Kubo)…"
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64) KUBO_ARCH="arm64" ;;
    x86_64)  KUBO_ARCH="amd64" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac
  KUBO_VER="v0.32.1"
  TMP="$(mktemp -d)"
  curl -fsSL "https://dist.ipfs.tech/kubo/${KUBO_VER}/kubo_${KUBO_VER}_linux-${KUBO_ARCH}.tar.gz" \
    | tar -xz -C "$TMP"
  sudo install -m 0755 "$TMP/kubo/ipfs" /usr/local/bin/ipfs
  rm -rf "$TMP"
fi

export IPFS_PATH="${GHOST_HOME}/.ipfs"
if [[ ! -d "$IPFS_PATH" ]]; then
  ipfs init
  ipfs config Datastore.StorageMax "180GB"
fi

systemctl --user enable ipfs 2>/dev/null || true
nohup ipfs daemon >/tmp/ipfs-ease-mirror.log 2>&1 &
sleep 2

mkdir -p "${GHOST_HOME}/.ghostcloud"
ln -sfn "$MIRROR_HOME/Documents" "${GHOST_HOME}/Documents"
ln -sfn "$MIRROR_HOME/Downloads" "${GHOST_HOME}/Downloads"
ln -sfn "$MIRROR_HOME/Projects" "${GHOST_HOME}/Projects"

cat >"${GHOST_HOME}/.ghostcloud/ease-mirror.info" <<INFO
product=Ease Mirror
ghost_home=${MIRROR_HOME}
wired_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INFO

echo ""
echo "Ghost Home wired:"
echo "  ${MIRROR_HOME}"
echo "  Documents/Downloads/Projects → GhostHome"
echo ""
echo "On your Mac, sync with: gc-store ~/path/to/file"
echo "Or: ghostcloud list"
