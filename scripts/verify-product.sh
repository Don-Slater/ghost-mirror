#!/usr/bin/env bash
# Ghost Mirror product smoke tests — build, bundle, CLI, optional install.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ease Mirror"
BUNDLE="${ROOT}/${APP_NAME}.app"
INSTALLED="/Applications/${APP_NAME}.app"
DO_INSTALL=0
DO_OPEN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --install   Build, verify, then install to /Applications
  --open      After install, launch the app (implies --install)
  -h, --help  Show this help

Runs release build checks on ${APP_NAME}.app bundle contents, icon assets,
hero logo PNG, codesign, and ease-mirror-cli smoke commands.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) DO_INSTALL=1 ;;
    --open) DO_INSTALL=1; DO_OPEN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

pass=0
fail=0

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "  PASS  $label"
    pass=$((pass + 1))
  else
    echo "  FAIL  $label" >&2
    fail=$((fail + 1))
  fi
}

section() {
  echo ""
  echo "== $1 =="
}

section "Build (release)"
bash "${ROOT}/scripts/build.sh" --release

TARGET_BUNDLE="$BUNDLE"
if [[ "$DO_INSTALL" -eq 1 ]]; then
  section "Install to /Applications"
  bash "${ROOT}/scripts/install-applications.sh"
  TARGET_BUNDLE="$INSTALLED"
  qlmanage -r >/dev/null 2>&1 || true
  qlmanage -r cache >/dev/null 2>&1 || true
  touch "$TARGET_BUNDLE"
fi

RES="${TARGET_BUNDLE}/Contents/Resources"
MACOS="${TARGET_BUNDLE}/Contents/MacOS"
PLIST="${TARGET_BUNDLE}/Contents/Info.plist"

section "Bundle structure"
check "app bundle exists" test -d "$TARGET_BUNDLE"
check "Info.plist exists" test -f "$PLIST"
check "EaseMirror binary exists" test -x "${MACOS}/EaseMirror"
check "ease-mirror-cli exists" test -x "${MACOS}/ease-mirror-cli"
check "AppIcon.icns bundled" test -f "${RES}/AppIcon.icns"
check "hero logo PNG bundled" test -f "${RES}/ghost-mirror-logo-replica.png"
check "scripts directory bundled" test -d "${RES}/scripts"
check "make-app-icon.sh bundled" test -f "${RES}/scripts/make-app-icon.sh"

section "Info.plist"
check "CFBundleIconFile = AppIcon" \
  grep -q "<string>AppIcon</string>" "$PLIST"
check "CFBundleExecutable = EaseMirror" \
  grep -q "<string>EaseMirror</string>" "$PLIST"
check "LSMinimumSystemVersion present" \
  grep -q "LSMinimumSystemVersion" "$PLIST"

section "Asset integrity"
check "AppIcon.icns non-empty" test -s "${RES}/AppIcon.icns"
check "hero logo PNG non-empty" test -s "${RES}/ghost-mirror-logo-replica.png"
check "icon source ghost PNG in repo" test -s "${ROOT}/Resources/ghost-mirror-icon-ghost.png"

if swift - <<'SWIFT' "${RES}/ghost-mirror-logo-replica.png" "${RES}/AppIcon.icns"
import AppKit
import Foundation

let args = CommandLine.arguments
var ok = true

func requireImage(_ path: String, label: String, minWidth: CGFloat) {
    guard let img = NSImage(contentsOf: URL(fileURLWithPath: path)) else {
        fputs("FAIL  \(label): cannot load image\n", stderr)
        ok = false
        return
    }
    if img.size.width < minWidth {
        fputs("FAIL  \(label): width \(img.size.width) < \(minWidth)\n", stderr)
        ok = false
        return
    }
    print("  PASS  \(label) loads (\(Int(img.size.width))x\(Int(img.size.height)))")
}

requireImage(args[1], label: "hero logo PNG decodes", minWidth: 200)
requireImage(args[2], label: "AppIcon.icns decodes", minWidth: 16)
exit(ok ? 0 : 1)
SWIFT
then
  pass=$((pass + 2))
else
  fail=$((fail + 2))
fi

section "Codesign"
if codesign --verify --deep --strict "$TARGET_BUNDLE" 2>/dev/null; then
  echo "  PASS  codesign verify"
  pass=$((pass + 1))
else
  echo "  FAIL  codesign verify" >&2
  fail=$((fail + 1))
fi

section "CLI smoke"
check "cli help exits 0" "${MACOS}/ease-mirror-cli" help
check "cli paths exits 0" "${MACOS}/ease-mirror-cli" paths
check "cli list exits 0" "${MACOS}/ease-mirror-cli" list

section "Icon generation (idempotent)"
bash "${ROOT}/scripts/make-app-icon.sh" >/dev/null
check "make-app-icon.sh regenerates icns" test -s "${ROOT}/Resources/AppIcon.icns"

section "Swift compile (debug)"
swift build >/dev/null
check "swift build debug" test -x "${ROOT}/.build/debug/EaseMirror"

echo ""
echo "----------------------------------------"
echo "Results: ${pass} passed, ${fail} failed"
echo "Bundle:  ${TARGET_BUNDLE}"

if [[ "$fail" -gt 0 ]]; then
  echo "Product verification FAILED" >&2
  exit 1
fi

echo "Product verification PASSED"

if [[ "$DO_OPEN" -eq 1 ]]; then
  echo "Launching ${TARGET_BUNDLE} ..."
  open "$TARGET_BUNDLE"
fi
