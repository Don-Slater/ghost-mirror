#!/usr/bin/env bash
# Ghost Mirror — wire cloud Ubuntu to feel like a laptop (GhostHome + shortcuts + CLI).
# Run ON the VPS (or via: bash wire-laptop-mac.sh)
set -euo pipefail

GHOST_USER="${GHOST_USER:-root}"
GHOST_HOME="$(getent passwd "$GHOST_USER" 2>/dev/null | cut -d: -f6 || echo "${HOME}")"
MIRROR_HOME="${GHOST_HOME}/GhostHome"
APP_URL="${GHOST_MIRROR_APP_URL:-https://ghostcloud.srv1699052.hstgr.cloud}"
GC_APP="${GHOSTCLOUD_APP_DIR:-/opt/ghostcloud-app}"

echo "=== Ghost Mirror — wire laptop (cloud) ==="
echo "User: ${GHOST_USER}  Home: ${GHOST_HOME}"

mkdir -p "${MIRROR_HOME}"/{Documents,Downloads,Projects}
mkdir -p "${GHOST_HOME}/.ghostcloud"

# Home folders → GhostHome (laptop layout)
# If a real folder already exists, merge into GhostHome then replace with symlink.
wire_link() {
  local name="$1"
  local target="${MIRROR_HOME}/${name}"
  local link="${GHOST_HOME}/${name}"
  mkdir -p "${target}"
  if [[ -L "${link}" ]]; then
    return 0
  fi
  if [[ -d "${link}" && ! -L "${link}" ]]; then
    shopt -s dotglob nullglob
    for item in "${link}"/*; do
      [[ -e "${item}" ]] || continue
      base="$(basename "${item}")"
      if [[ ! -e "${target}/${base}" ]]; then
        mv "${item}" "${target}/"
      fi
    done
    shopt -u dotglob nullglob
    rmdir "${link}" 2>/dev/null || rm -rf "${link}"
  fi
  ln -sfn "${target}" "${link}"
}

wire_link Documents
wire_link Downloads
wire_link Projects

touch "${GHOST_HOME}/.ghostcloud/command_inbox.txt"

# ghostcloud CLI on PATH
if [[ -f "${GC_APP}/ghostcloud-cli.py" ]]; then
  cat >/usr/local/bin/ghostcloud <<EOF
#!/bin/bash
exec ${GC_APP}/.venv/bin/python3 ${GC_APP}/ghostcloud-cli.py "\$@"
EOF
  chmod +x /usr/local/bin/ghostcloud
fi

# Shell starts in GhostHome when interactive
MARKER="# ghost-mirror-laptop"
if ! grep -q "$MARKER" "${GHOST_HOME}/.bashrc" 2>/dev/null; then
  cat >>"${GHOST_HOME}/.bashrc" <<BASH

${MARKER}
export GHOST_HOME="${MIRROR_HOME}"
export GHOST_MIRROR_APP_URL="${APP_URL}"
if [[ -d "\${GHOST_HOME}" && \$- == *i* ]]; then
  cd "\${GHOST_HOME}" 2>/dev/null || true
fi
alias ll='ls -la'
alias home='cd ${MIRROR_HOME} && pwd'
alias vault='echo "Open Library: ${APP_URL}/library"'
BASH
fi

cat >"${GHOST_HOME}/.ghostcloud/laptop.info" <<INFO
product=Ghost Mirror
mode=cloud-laptop
ghost_home=${MIRROR_HOME}
app_url=${APP_URL}
bridge_url=${APP_URL}/bridge
library_url=${APP_URL}/library
wired_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INFO

# XFCE desktop shortcuts (if desktop installed)
DESKTOP_DIR="${GHOST_HOME}/Desktop"
if [[ -d "${GHOST_HOME}/Desktop" ]] || mkdir -p "${DESKTOP_DIR}" 2>/dev/null; then
  cat >"${DESKTOP_DIR}/Ghost Mirror Library.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=Ghost Mirror Library
Comment=1 TB encrypted vault
Exec=firefox ${APP_URL}/library
Icon=folder
Terminal=false
DESK
  cat >"${DESKTOP_DIR}/Ghost Mirror Terminal.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=Ghost Mirror Terminal
Comment=Terminal bridge
Exec=firefox ${APP_URL}/bridge
Icon=utilities-terminal
Terminal=false
DESK
  cat >"${DESKTOP_DIR}/GhostHome.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=GhostHome
Comment=Your cloud home folder
Exec=thunar ${MIRROR_HOME}
Icon=user-home
Terminal=false
DESK
  chmod +x "${DESKTOP_DIR}"/*.desktop 2>/dev/null || true
fi

# Thunar bookmarks
if command -v xfconf-query &>/dev/null; then
  xfconf-query -c thunar -p /last-view -n -t string -s ThunarDetailsViewState 2>/dev/null || true
fi

echo ""
echo "Laptop wired:"
echo "  GhostHome:  ${MIRROR_HOME}"
echo "  Documents:  ${GHOST_HOME}/Documents  → vault-backed home"
echo "  Downloads:  ${GHOST_HOME}/Downloads"
echo "  Projects:   ${GHOST_HOME}/Projects"
echo "  Library:    ${APP_URL}/library"
echo "  Terminal:   ${APP_URL}/bridge"
echo "  CLI:        ghostcloud list  (needs vault password)"
echo ""
ls -la "${MIRROR_HOME}"
