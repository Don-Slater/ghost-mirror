#!/usr/bin/env bash
# Ease Mirror — local VM diagnostic + optional repair (quality-first boot).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="${ROOT}/.build/release/ghost-mirror-cli"
REPAIR=0

[[ "${1:-}" == "--repair" ]] && REPAIR=1

pass() { echo "  OK   $1"; }
fail() { echo "  FAIL $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN $1"; }

FAIL=0

echo ""
echo "============================================"
echo "  Ease Mirror — local VM diagnostic"
echo "  $(date)"
echo "  Quality-first · stable boot"
echo "============================================"
echo ""

echo "── Mac ──"
if sysctl -n hw.optional.arm.FEAT_VHE 2>/dev/null | grep -q 1 || [[ "$(uname -m)" == "arm64" ]]; then
  pass "Apple Silicon"
else
  warn "Not Apple Silicon — local VM needs M-series Mac"
fi

if [[ -x "${ROOT}/Ease Mirror.app/Contents/MacOS/EaseMirror" ]] || [[ -x "/Applications/Ease Mirror.app/Contents/MacOS/EaseMirror" ]]; then
  pass "Ease Mirror.app"
else
  fail "App missing — run: cd ${ROOT} && ./scripts/build.sh --release"
fi

if [[ -x "$CLI" ]]; then
  pass "ghost-mirror-cli"
else
  fail "CLI missing — run: cd ${ROOT} && swift build -c release"
fi

CRASHES=$(ls -1 ~/Library/Logs/DiagnosticReports/EaseMirror-*.ips 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CRASHES" -gt 0 ]]; then
  warn "Past app crashes: ${CRASHES} (main-thread VM start was fixed in build)"
else
  pass "No EaseMirror crash logs"
fi

echo ""
echo "── ISO ──"
ISO="${HOME}/Library/Application Support/EaseMirror/ISOs/ubuntu-24.04.4-desktop-arm64.iso"
if [[ -f "$ISO" ]]; then
  SZ=$(stat -f%z "$ISO" 2>/dev/null || stat -c%s "$ISO")
  if [[ "$SZ" -gt 2500000000 ]]; then
    pass "Ubuntu ISO ($(($SZ / 1000000000))GB)"
  else
    fail "ISO too small — re-download: ghost-mirror-cli download-iso"
  fi
else
  fail "ISO missing — ghost-mirror-cli download-iso"
fi

echo ""
echo "── Local mirror ──"
if [[ -x "$CLI" ]]; then
  LIST=$("$CLI" list 2>/dev/null || true)
  if [[ -z "$LIST" ]]; then
    warn "No local mirrors — create one in the app"
  else
    echo "$LIST"
    while IFS= read -r line; do
      id="${line%%$'\t'*}"
      rest="${line#*$'\t'}"
      [[ -z "$id" || "$id" == "$line" ]] && continue
      VM_DIR="${HOME}/Library/Application Support/EaseMirror/VMs/${id}"
      if [[ -f "${VM_DIR}/disk.img" ]]; then
        pass "disk.img ($id)"
      else
        fail "disk.img missing ($id)"
      fi
      if echo "$rest" | grep -q needs-install; then
        warn "Still installing — do NOT run RUN-CLIPBOARD (kernel panic)"
      fi
      if [[ "$REPAIR" -eq 1 ]]; then
        echo "  Repairing EFI for ${id}..."
        "$CLI" repair "$id" || fail "repair $id"
      fi
      "$CLI" diagnose "$id" 2>/dev/null || true
    done <<< "$LIST"
  fi
else
  warn "Skip mirror checks — CLI not built"
fi

echo ""
echo "── Rules (Ease Audio quality) ──"
echo "  • Install: lighter RAM/CPU — no share folder"
echo "  • After Mark Installed: full power + clipboard"
echo "  • Kernel panic during install? Run: bash ${ROOT}/scripts/diagnose-local-vm.sh --repair"
echo ""

echo "============================================"
if [[ "$FAIL" -eq 0 ]]; then
  echo "  LOCAL VM: PASS — open app and Start"
  echo "  open \"/Applications/Ease Mirror.app\""
else
  echo "  LOCAL VM: ${FAIL} issue(s) — fix above"
fi
echo "============================================"
echo ""

exit "$FAIL"
