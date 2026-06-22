#!/usr/bin/env bash
# Ease Mirror Cloud Desktop — Linux-native XFCE + TigerVNC + noVNC (no Microsoft/RDP).
set -euo pipefail

ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
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

REMOTE_SCRIPT="$(cat <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "=== Ease Mirror — Linux desktop (VNC + noVNC) ==="

apt-get update -qq
apt-get install -y -qq \
  tigervnc-standalone-server \
  novnc \
  websockify \
  dbus-x11 \
  xfce4 \
  xfce4-goodies \
  firefox \
  thunar

# Stop/remove Microsoft-protocol RDP if present — Ease Mirror is Linux-native only
if systemctl is-active xrdp &>/dev/null; then
  systemctl disable --now xrdp xrdp-sesman 2>/dev/null || true
fi

install -d -m 700 /root/.vnc

if [[ ! -f /root/.vnc/passwd ]]; then
  VNC_PASS="$(openssl rand -base64 16 | tr -d '/+=' | head -c 16)"
  printf '%s\n%s\nn\n' "$VNC_PASS" "$VNC_PASS" | vncpasswd
  echo "$VNC_PASS" > /root/.vnc/ease-mirror-vnc.password
  chmod 600 /root/.vnc/ease-mirror-vnc.password
  echo "NEW_VNC_PASSWORD=$VNC_PASS"
else
  echo "VNC password file already exists (/root/.vnc/passwd)"
fi

cat >/root/.vnc/xstartup <<'XSTART'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
startxfce4 &
XSTART
chmod +x /root/.vnc/xstartup

# TigerVNC — localhost only (Mac reaches via SSH tunnel)
cat >/etc/systemd/system/ease-mirror-vnc.service <<'UNIT'
[Unit]
Description=Ease Mirror TigerVNC (XFCE)
After=network.target

[Service]
Type=forking
User=root
ExecStartPre=-/usr/bin/vncserver -kill :1
ExecStart=/usr/bin/vncserver :1 -geometry 1280x800 -depth 24 -localhost yes
ExecStop=/usr/bin/vncserver -kill :1
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

# noVNC — web bridge on localhost:6080
cat >/etc/systemd/system/ease-mirror-novnc.service <<'UNIT'
[Unit]
Description=Ease Mirror noVNC (Linux web desktop)
After=ease-mirror-vnc.service
Requires=ease-mirror-vnc.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable ease-mirror-vnc ease-mirror-novnc
systemctl restart ease-mirror-vnc
sleep 2
systemctl restart ease-mirror-novnc

echo "vnc:   $(systemctl is-active ease-mirror-vnc)"
echo "novnc: $(systemctl is-active ease-mirror-novnc)"
echo "GhostHome: $(ls /root/GhostHome 2>/dev/null | tr '\n' ' ')"
REMOTE
)"

echo "Installing Linux-native desktop on ${SSH_USER}@${IP}…"
OUTPUT="$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${IP}" "bash -s" <<<"$REMOTE_SCRIPT")"
echo "$OUTPUT"

VNC_PASS="$(echo "$OUTPUT" | sed -n 's/^NEW_VNC_PASSWORD=//p')"
mkdir -p "${HOME}/.ben_studio"

# Rewrite cloud env cleanly (no RDP keys)
{
  echo "EASE_MIRROR_CLOUD_IP=${IP}"
  echo "EASE_MIRROR_CLOUD_USER=${SSH_USER}"
  echo "EASE_MIRROR_SSH_KEY=${SSH_KEY}"
  echo "EASE_MIRROR_HOST=srv1699052.hstgr.cloud"
  echo "EASE_MIRROR_GHOST_URL=https://ghostcloud.srv1699052.hstgr.cloud"
  echo "EASE_MIRROR_DESKTOP=xfce-vnc"
  echo "EASE_MIRROR_VNC_LOCAL=127.0.0.1:5901"
  echo "EASE_MIRROR_NOVNC_LOCAL=http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale"
  echo "EASE_MIRROR_DESKTOP_READY=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} > "${HOME}/.ben_studio/ease_mirror_cloud.env"

if [[ -n "$VNC_PASS" ]]; then
  echo "EASE_MIRROR_VNC_PASSWORD=${VNC_PASS}" >> "${HOME}/.ben_studio/ease_mirror_cloud.env"
  chmod 600 "${HOME}/.ben_studio/ease_mirror_cloud.env"
  echo ""
  echo "VNC password (saved ~/.ben_studio/ease_mirror_cloud.env): ${VNC_PASS}"
fi

cat >"${HOME}/Desktop/Ease Mirror Cloud.command" <<CMD
#!/bin/zsh
exec bash "${HOME}/BenStudio/EaseMirror/scripts/connect-cloud-desktop.sh"
CMD
chmod +x "${HOME}/Desktop/Ease Mirror Cloud.command"
rm -f "${HOME}/Desktop/Ease Mirror Cloud (RDP).command" 2>/dev/null || true

echo ""
echo "=== Linux desktop ready (no Microsoft) ==="
echo "  Open: ~/Desktop/Ease Mirror Cloud.command"
echo "  Or:   Ease Mirror app → Cloud Mirror → Open Cloud Desktop"
echo "  Stack: XFCE + TigerVNC + noVNC over SSH tunnel"
