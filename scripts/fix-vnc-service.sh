#!/usr/bin/env bash
# Stop ease-mirror-vnc restart loop when display :1 is already running.
set -euo pipefail

ENV="${HOME}/.ben_studio/ease_mirror_cloud.env"
IP="${1:-72.62.212.87}"
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/ben_remote_ubuntu_ed25519"

if [[ -f "$ENV" ]]; then
  # shellcheck source=/dev/null
  source "$ENV"
  IP="${EASE_MIRROR_CLOUD_IP:-$IP}"
  SSH_USER="${EASE_MIRROR_CLOUD_USER:-$SSH_USER}"
  SSH_KEY="${EASE_MIRROR_SSH_KEY:-$SSH_KEY}"
fi

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${IP}" bash <<'REMOTE'
set -euo pipefail

# If VNC already healthy, disable the broken systemd loop (keeps crashing on "already running")
if pgrep -x Xtigervnc >/dev/null; then
  systemctl disable --now ease-mirror-vnc 2>/dev/null || true
  systemctl reset-failed ease-mirror-vnc 2>/dev/null || true
  echo "VNC display :1 already running — disabled restart loop"
else
  cat >/root/.vnc/xstartup <<'XSTART'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
vncconfig -iconic &
exec startxfce4
XSTART
  chmod +x /root/.vnc/xstartup
  vncserver -kill :1 2>/dev/null || true
  sleep 1
  vncserver :1 -geometry 1280x800 -depth 24 -localhost yes
  echo "Started VNC display :1"
fi

pkill -9 -f 'websockify.*6080' 2>/dev/null || true
sleep 1
nohup /usr/bin/websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901 \
  >/var/log/ease-mirror-novnc.log 2>&1 &
sleep 1

echo "Xtigervnc: $(pgrep -x Xtigervnc >/dev/null && echo active || echo down)"
echo "websockify: $(pgrep -f 'websockify.*6080' >/dev/null && echo active || echo down)"
REMOTE

echo "VPS desktop stabilised."
