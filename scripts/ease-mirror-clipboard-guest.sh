#!/usr/bin/env bash
# Mount Ease Mirror share + sync clipboard with Mac via shared folder.
set -euo pipefail

TAG="${EASE_MIRROR_SHARE_TAG:-EaseMirrorShare}"
MOUNT="${EASE_MIRROR_SHARE_MOUNT:-$HOME/EaseMirrorShare}"
HOST_FILE="$MOUNT/host_clipboard.txt"
GUEST_FILE="$MOUNT/guest_clipboard.txt"
HEARTBEAT="$MOUNT/guest_clipboard_alive"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/ease-mirror-clipboard.pid"

mount_share() {
  if ! (ls "/sys/fs/virtiofs/${TAG}" >/dev/null 2>&1 || \
        find /sys -maxdepth 4 -name "*${TAG}*" 2>/dev/null | grep -q .); then
    echo "VirtioFS share not available — Mark Installed on Mac, then Stop + Start."
    exit 1
  fi
  mkdir -p "$MOUNT"
  if mountpoint -q "$MOUNT" 2>/dev/null; then
    return 0
  fi
  if ! mount -t virtiofs "$TAG" "$MOUNT" 2>/dev/null; then
    sudo mkdir -p "$MOUNT"
    sudo mount -t virtiofs "$TAG" "$MOUNT"
  fi
}

ensure_xclip() {
  command -v xclip >/dev/null || {
    sudo apt-get update -qq
    sudo apt-get install -y -qq xclip
  }
}

read_clip() {
  xclip -selection clipboard -o 2>/dev/null || true
}

write_clip() {
  printf '%s' "$1" | xclip -selection clipboard 2>/dev/null || true
}

sync_loop() {
  local last=""
  while true; do
    date +%s > "$HEARTBEAT" 2>/dev/null || true
    if [[ -d "$MOUNT" ]]; then
      cur="$(read_clip)"
      if [[ -n "$cur" && "$cur" != "$last" ]]; then
        printf '%s' "$cur" > "$GUEST_FILE"
        last="$cur"
      fi
      if [[ -f "$HOST_FILE" ]]; then
        host="$(tr -d '\0' < "$HOST_FILE" 2>/dev/null || true)"
        if [[ -n "$host" && "$host" != "$cur" && "$host" != "$last" ]]; then
          write_clip "$host"
          last="$host"
        fi
      fi
    fi
    sleep 0.35
  done
}

stop_old() {
  if [[ -f "$PID_FILE" ]]; then
    old="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old" ]] && kill -0 "$old" 2>/dev/null; then
      kill "$old" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
}

case "${1:-start}" in
  start)
    mount_share
    ensure_xclip
    touch "$HOST_FILE" "$GUEST_FILE" "$HEARTBEAT"
    stop_old
    sync_loop &
    echo $! > "$PID_FILE"
    echo "Clipboard bridge running at $MOUNT"
    ;;
  stop)
    stop_old
    echo "Stopped."
    ;;
  status)
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "running mount=$MOUNT"
    else
      echo "stopped"
    fi
    ;;
  *)
    echo "Usage: $0 [start|stop|status]"
    exit 1
    ;;
esac
